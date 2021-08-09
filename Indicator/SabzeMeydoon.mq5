#property copyright "2009-2017, MetaQuotes Software Corp."
#property link "http://www.mql5.com"
#property description "Relative Strength Index"
//--- indicator settings
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 20
#property indicator_level2 80
#property indicator_buffers 1
#property indicator_plots 1
#property indicator_type1 DRAW_LINE
#property indicator_color1 DodgerBlue
//--- input parameters
input int InpPeriod = 10; // Period
//--- indicator buffers
double SMBuffer[];

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
  //--- set accuracy
  IndicatorSetInteger(INDICATOR_DIGITS, 2);
  //--- sets first bar from what index will be drawn
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, Period);
  //--- name for DataWindow and indicator subwindow label
  IndicatorSetString(INDICATOR_SHORTNAME, "SM(" + string(Period) + ")");
}

int OnCalculate(const int rates_total, const int prev_calculated,
                const int begin, const double &price[]) {
  int first;
  if (prev_calculated == 0)
    first = Period - 1 + begin;
  else
    first = prev_calculated - 1;

  double min = iLow(Symbol(), Period(),
                    iLowest(Symbol(), Period(), MODE_LOW, Period, 0));
  double max = iHigh(Symbol(), Period(),
                     iHighest(Symbol(), Period(), MODE_HIGH, Period, 0));
  Comment(max);

  for (int i = first; i < rates_total && !IsStopped(); i++) {
    SMBuffer[i] = (price[i] - min) * 100 / (max - min);
  }
  return (rates_total);
}