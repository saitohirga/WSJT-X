--
--  WSJTAppDelegate.applescript
--  KVASD-installer
--
--    This script is a drag and drop target that expects a WSJT-X app bundle path.
--    It can also be opened with a file list or by dropping a suitable WSJT-X app
--    bundle onto it. Alternatively a target WSJT-X application bundle may be
--    selected by clicking the "Choose target ..." button.
--
--    It fetches the KVASD EULA text and displays it in a dialog which the reader
--    must at least scroll to the end before clicking the Agree button which then
--    downloads the appropriate KVASD executable. The MD5 hash checksum is checked
--    on the KVASD executable.
--
--    Once the EULA has been accepted the "Install" button is enabled to install
--    the KVASD executable into the target WSJT-X application bundle(s) and the
--    RPATHs are modified to reference the libgcc support libraries inside the
--    WSJT-X application bundle.
--
--  Created by Bill Somerville (G4WJS) on 12/11/2014.
--
--  The author of this work hereby waives all claim of copyright (economic and moral)
--  in this work and immediately places it in the public domain; it may be used, distorted
--  or destroyed in any manner whatsoever without further attribution or notice to the creator.
--

-- curl wraps cURL to download files
script curl
    on download(|url|, fileName, destination)
        set |file| to destination & fileName
        try
            do shell script "curl --fail --retry 5 --silent --show-error --output " & |file| & " " & |url| & fileName
        on error errorString
            error "An error occurred downloading:" & return & |url| & fileName & return & return & errorString
        end try
        return |file| as POSIX file
    end download
    
    on downloadMD5(|url|, fileName)
        set md5Ext to ".md5"
        try
            return do shell script "curl --fail --retry 5 --silent " & |url| & fileName & md5Ext ¬
                & " | awk '{match($0,\"[[:xdigit:]]{32}\"); print substr($0,RSTART,RLENGTH)}'"
        on error errorString
            error "An error occurred downloading" & return & return & fileName & md5Ext & return & return & errorString
        end try
    end downloadMD5
end script

-- kvasd looks after fetching kvasd files from the web source
script kvasd
    property serverPath : "https://svn.code.sf.net/p/wsjt/wsjt/trunk/kvasd-binary/"
    property targetName : "kvasd"
    
    on destination()
        return system attribute "TMPDIR"
    end destination
    
    on fetchEULA()
        return curl's download(serverPath,targetName  & "_eula.txt",my destination())
    end fetchEULA
    
    on fetchBinary()
        set |url| to serverPath & do shell script "echo `uname -s`-`uname -m`" & "/"
        set md5Sum to curl's downloadMD5(|url|,targetName)
        set |file| to curl's download(|url|,targetName,my destination())
        set md5Calc to do shell script "md5 " & (POSIX path of |file|) & " | cut -d' ' -f4"
        if md5Calc ≠ md5Sum then
            error "KVASD download corrupt MD5 hash check" & return & return ¬
                    & " expected [" & md5Sum & "]" & return ¬
                    & "   actual [" & md5Calc & "]" ¬
                number 500
        end if
    end fetchBinary
    
    on saveLicense()
        set dest to choose folder ¬
            with prompt "Specify folder to save license to" ¬
            default location (path to documents folder)
        tell application "Finder" to ¬
            duplicate (my destination() & targetName & "_eula.txt") as POSIX file to dest
    end saveLicense
    
    on printLicense()
        tell application "Finder" to ¬
            print (my destination() & targetName & "_eula.txt") as POSIX file
    end printLicense
    
    on cleanUp()
        tell application "Finder"
            if exists (my destination() & targetName & "_eula.txt") as POSIX file then
                delete (my destination() & targetName & "_eula.txt") as POSIX file
            end if
            if exists (my destination() & targetName) as POSIX file then
                delete (my destination() & targetName) as POSIX file
            end if
        end tell
    end cleanUp
end script

script WSJTAppDelegate
	property parent : class "NSObject"
    
    property mainWindow : missing value
    property eulaTextView : missing value
    property progressBar : missing value
    property saveButton : missing value
    property printButton : missing value
    property agreeCheckBox : missing value
    property chooseTargetButton : missing value
    property installButton : missing value
    
    property bundlesToProcess : {}
    
    global defaultNotificationCentre
    global licenceAgreed
    
    on split(theText,theDelimiters)
        set oldDelimiters to AppleScript's text item delimiters
        set AppleScript's text item delimiters to theDelimiters
        set theResult to the text items of theText
        set AppleScript's text item delimiters to oldDelimiters
        return theResult
    end split
    
    -- do the install
    on process()
        repeat with bundlePath in bundlesToProcess
            try
                set wsjtxBundle to current application's NSBundle's bundleWithPath_(bundlePath)
                if wsjtxBundle = missing value or wsjtxBundle's bundleIdentifier() as text ≠ "org.k1jt.wsjtx" then
                    error "Not an appropriate WSJT-X application bundle: " & return & return ¬
                    & bundlePath as text number 501
                end if
                set installRoot to wsjtxBundle's bundlePath() as text
                display dialog "Install KVASD into Aplication Bundle" & return & return ¬
                    & installRoot ¬
                    buttons {"Ok", "Skip"} default button {"Ok"}
                if button returned of result = "Ok" then
                    try
                        set target to installRoot & "/Contents/MacOS/" & kvasd's targetName
                        do shell script "cp " & kvasd's destination() & kvasd's targetName & space & target
                        repeat with theLine in paragraphs of (do shell script "otool -L " & target)
                            if theLine contains ".dylib" and not theLine contains "libSystem" then
                                set theDylib to 2nd item of split(theLine,{tab,space})
                                do shell script "install_name_tool -change " & theDylib & " @executable_path/" & last item of split(theDylib,{"/"}) & space & target
                            end if
                        end repeat
                        log do shell script "chmod +x " & target
                        display alert "KVASD installed into application bundle:" & return & return & installRoot ¬
                            buttons {"Ok"} default button "Ok" ¬
                            giving up after 5
                    on error errorString
                        error "Failed to move KVASD into application bundle:" & return & return & installRoot ¬
                            & return & return & "Error: " & errorString
                    end try
                end if
            on error errorString
                display alert errorString as warning buttons {"Ok"} default button "Ok"
            end try
        end repeat
    end process

    --
    -- NSApplicationDelegate Protocol
    --
    on applicationWillFinishLaunching_(aNotification)
        try
--            mainWindow's registerForDraggedTypes_({"public.file-url"})
            
            set defaultNotificationCentre to current application's NSNotificationCenter's defaultCenter()
            set licenceAgreed to false
            eulaTextView's setEditable_(false)
            
            script downloadEula
                eulaTextView's setString_(read kvasd's fetchEULA())
            end script
            my doWithRetry(downloadEula)
            saveButton's setEnabled_(true)
            printButton's setEnabled_(true)
        
            -- add observers for view port changes on EULA text view
            set boundsChangeNotice to current application's NSViewBoundsDidChangeNotification
            set frameChangeNotice to current application's NSViewFrameDidChangeNotification
            defaultNotificationCentre's addObserver_selector_name_object_(me,"viewChanged:",boundsChangeNotice,missing value)
            defaultNotificationCentre's addObserver_selector_name_object_(me,"viewChanged:",frameChangeNotice,missing value)
        on error errorString
            abort(errorString)
        end try
    end applicationWillFinishLaunching_
    
    on applicationShouldTerminateAfterLastWindowClosed_(sender)
        return true
    end applicationShouldTerminateAfterLastWindowClosed_
	
	on applicationWillTerminate_(sender)
        defaultNotificationCentre's removeObserver_(me)
        kvasd's cleanUp()
	end applicationWillTerminate_
    
    --
    -- NSDraggingDestination (NSWindow Delgate) Protocol (Not working on 10.7)
    --
    
    -- Accept Generic drag&drop sources
--    on draggingEntered_(sender)
--        return current application's NSDragOperationGeneric
--    end draggingEntered_
    
    -- Process a drop on our window
--    on performDragOperation_(sender)
--        try
--            set pb to sender's draggingPasteboard()
--            if pb's types() as list contains current application's NSURLPboardType then
--                set options to {NSPasteboardURLReadingContentsConformToTypesKey:{"com.apple.application-bundle"}}
--                repeat with u in pb's readObjectsForClasses_options_({current application's |NSURL|},options)
--                    copy u's |path| to end of bundlesToProcess
--                end repeat
--                if bundlesToProcess ≠ {} and licenceAgreed then
--                    installButton's setEnabled_(true)
--                end if
--                return true
--            end if
--        on error errorString
--            abort(errorString)
--        end try
--        return false
--    end performDragOperation_
    
    --
    -- UI handlers
    --
    
    -- Save EULA
    on doSave_(sender)
        try
            kvasd's saveLicense()
        on error errorString number errorNumber
            if errorNumber is equal to -128 then
                -- just ignore Cancel
            else
                abort(errorString)
            end if
        end try
    end doSave_
    
    -- Save EULA
    on doPrint_(sender)
        try
            kvasd's printLicense()
        on error errorString number errorNumber
            if errorNumber is equal to -128 then
                -- just ignore Cancel
            else
                abort(errorString)
            end if
        end try
    end doPrint_
    
    -- Agree Button handler
    on doAgree_(sender)
        if agreeCheckBox's state() as boolean then
            try
                script downloadKvasd
                    kvasd's fetchBinary()
                end script
                my doWithRetry(downloadKvasd)
            on error errorString
                abort(errorString)
            end try
            agreeCheckBox's setEnabled_(false)
            set licenceAgreed to true
            if bundlesToProcess ≠ {} then
                installButton's setEnabled_(true)
            end if
        end if
    end doAgree_

    -- Choose target button handler
    on doChooseTarget_(sender)
        try
            repeat with target in choose file ¬
                    with prompt "Choose the WSJT-X application bundle you wish to install KVASD into" ¬
                    of type "com.apple.application-bundle" ¬
                    default location "/Applications" as POSIX file as alias ¬
                    invisibles false ¬
                    multiple selections allowed true
                copy POSIX path of target to end of bundlesToProcess
            end repeat
            if bundlesToProcess ≠ {} and licenceAgreed then
                installButton's setEnabled_(true)
            end if
        on error number -128
            -- just ignore Cancel
        end try
    end doChooseTarget_

    -- Install button handler
    on doInstall_(sender)
        try
            process()
            set bundlesToProcess to {}
            installButton's setEnabled_(false)
        on error errorString
            abort(errorString)
        end try
    end doInstall_

    -- handler called on eulaTextView scroll or view changes
    -- enables agree/install button once the bottom is reached
    on viewChanged_(aNotification)
        try
            set dr to eulaTextView's |bounds| as record
            set vdr to eulaTextView's visibleRect as record
            if height of |size| of dr - (y of origin of vdr + height of |size| of vdr) is less than or equal to 0 ¬
                    and not licenceAgreed then
                agreeCheckBox's setEnabled_(true)
            end if
        on error errorString
            abort(errorString)
        end try
    end viewChanged

    -- Do something with retries
    on doWithRetry(action)
        set done to false
        repeat until done
            try
                my progressAction(action)
                set done to true
            on error errorString
                set userCanceled to false
                try
                    set dialogResult to display alert errorString as warning ¬
                        buttons {"Cancel", "Retry"} default button "Retry" cancel button "Cancel"
                on error number -128
                    set userCanceled to true
                end try
                if userCanceled then
                    error "User canceled operation"
                end if
            end try
        end repeat
    end doWithRetry

    -- execute around handler to display a progress bar during an action
    on progressAction(action)
        progressBar's startAnimation_(me)
        tell action to run
        progressBar's stopAnimation_(me)
    end progressAction

    -- Abort handler
    on abort(errorString)
        display alert errorString as critical buttons {"Ok"} default button "Ok"
        quit
    end abort

    -- About menu item
    on doAbout_(sender)
        display alert "KVASD-installer v1.0"
    end onAbout_
end script
