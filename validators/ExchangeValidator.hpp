#ifndef EXCHANGE_VALIDATOR_HPP__
#define EXCHANGE_VALIDATOR_HPP__

#include <QValidator>

// ExchangeValidator - QValidator for Field Day and RTTY Roundup exchanges

class ExchangeValidator final
  : public QValidator
{
public:
  ExchangeValidator (QObject * parent = nullptr);

  // QValidator implementation
  State validate (QString& input, int& length) const override;

};

#endif
