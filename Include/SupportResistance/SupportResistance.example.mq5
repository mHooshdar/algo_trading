#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"
#include <SupportResistance.mqh>

int OnInit() { return (INIT_SUCCEEDED); }

void OnDeinit(const int reason) {}

void OnTick() {
  SupportResistanceRange test[];
  SupportResistance(0.001, 10, test);
  ArrayPrint(test);
}
