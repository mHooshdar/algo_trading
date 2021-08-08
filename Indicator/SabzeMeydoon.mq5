#property copyright "2009-2017, MetaQuotes Software Corp."
#property link "http://www.mql5.com"
#property description "Relative Strength Index"
//--- indicator settings
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 30
#property indicator_level2 70
#property indicator_buffers 3
#property indicator_plots 1
#property indicator_type1 DRAW_LINE
#property indicator_color1 DodgerBlue
//--- input parameters
input int InpPeriod = 100; // Period
//--- indicator buffers
double SMBuffer[];
double MaxBuffer[];
double MinBuffer[];

int Period;
void OnInit() {
  //--- check for input
  if (InpPeriod < 1) {
    Period = 100;
    PrintFormat("Incorrect value for input variable InpPeriodRSI = %d. "
                "Indicator will use value %d for calculations.",
                InpPeriod, Period);
  } else
    Period = InpPeriod;
  //--- indicator buffers mapping
  SetIndexBuffer(0, SMBuffer, INDICATOR_DATA);
  SetIndexBuffer(1, MaxBuffer, INDICATOR_CALCULATIONS);
  SetIndexBuffer(2, MinBuffer, INDICATOR_CALCULATIONS);
  //--- set accuracy
  IndicatorSetInteger(INDICATOR_DIGITS, 2);
  //--- sets first bar from what index will be drawn
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, Period);
  //--- name for DataWindow and indicator subwindow label
  IndicatorSetString(INDICATOR_SHORTNAME, "SM(" + string(Period) + ")");
}

int OnCalculate(const int rates_total, const int prev_calculated,
                const int begin, const double &price[]) {
  // if (rates_total <= ExtPeriodRSI)
  //   return (0);
  // //--- preliminary calculations
  // int pos = prev_calculated - 1;
  // if (pos <= ExtPeriodRSI) {
  //   double sum_pos = 0.0;
  //   double sum_neg = 0.0;
  //   //--- first RSIPeriod values of the indicator are not calculated
  //   ExtRSIBuffer[0] = 0.0;
  //   ExtPosBuffer[0] = 0.0;
  //   ExtNegBuffer[0] = 0.0;
  //   for (int i = 1; i <= ExtPeriodRSI; i++) {
  //     ExtRSIBuffer[i] = 0.0;
  //     ExtPosBuffer[i] = 0.0;
  //     ExtNegBuffer[i] = 0.0;
  //     double diff = price[i] - price[i - 1];
  //     sum_pos += (diff > 0 ? diff : 0);
  //     sum_neg += (diff < 0 ? -diff : 0);
  //   }
  //   //--- calculate first visible value
  //   ExtPosBuffer[ExtPeriodRSI] = sum_pos / ExtPeriodRSI;
  //   ExtNegBuffer[ExtPeriodRSI] = sum_neg / ExtPeriodRSI;
  //   if (ExtNegBuffer[ExtPeriodRSI] != 0.0)
  //     ExtRSIBuffer[ExtPeriodRSI] =
  //         100.0 - (100.0 / (1.0 + ExtPosBuffer[ExtPeriodRSI] /
  //                                     ExtNegBuffer[ExtPeriodRSI]));
  //   else {
  //     if (ExtPosBuffer[ExtPeriodRSI] != 0.0)
  //       ExtRSIBuffer[ExtPeriodRSI] = 100.0;
  //     else
  //       ExtRSIBuffer[ExtPeriodRSI] = 50.0;
  //   }
  //   //--- prepare the position value for main calculation
  //   pos = ExtPeriodRSI + 1;
  // }
  // //--- the main loop of calculations
  // for (int i = pos; i < rates_total && !IsStopped(); i++) {
  //   double diff = price[i] - price[i - 1];
  //   ExtPosBuffer[i] =
  //       (ExtPosBuffer[i - 1] * (ExtPeriodRSI - 1) + (diff > 0.0 ? diff :
  //       0.0)) / ExtPeriodRSI;
  //   ExtNegBuffer[i] = (ExtNegBuffer[i - 1] * (ExtPeriodRSI - 1) +
  //                      (diff < 0.0 ? -diff : 0.0)) /
  //                     ExtPeriodRSI;
  //   if (ExtNegBuffer[i] != 0.0)
  //     ExtRSIBuffer[i] = 100.0 - 100.0 / (1 + ExtPosBuffer[i] /
  //     ExtNegBuffer[i]);
  //   else {
  //     if (ExtPosBuffer[i] != 0.0)
  //       ExtRSIBuffer[i] = 100.0;
  //     else
  //       ExtRSIBuffer[i] = 50.0;
  //   }
  // }
  // //--- OnCalculate done. Return new prev_calculated.
  int min = iLowest(NULL, 0, MODE_LOW, Period, 0);
  int max = iHighest(NULL, 0, MODE_HIGH, Period, 0);
  for (int i = prev_calculated - 1; i < rates_total && !IsStopped(); i++) {
    SMBuffer[i] = (min + max) / 2;
  }
  return (rates_total);
}