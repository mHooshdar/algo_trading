#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

input double xHeight = 0.001;
input int candlesNo = 10;

double highLowArray[];
double highLowWeightArray[][];

int OnInit() { return (INIT_SUCCEEDED); }

void OnDeinit(const int reason) {}

void OnTick() {
  double min = iLow(Symbol(), Period(),
                    iLowest(Symbol(), Period(), MODE_LOW, candlesNo, 0));
  double max = iHigh(Symbol(), Period(),
                     iHighest(Symbol(), Period(), MODE_HIGH, candlesNo, 0));

  int rangeCount = MathCeil((max - min) / xHeight);
  Print(rangeCount);
  Print("MAXIMUM:", max);
  Print("MINIMUM:", min);

  ArrayResize(highLowArray, 2 * candlesNo);
  ArrayResize(highLowWeightArray, rangeCount);

  for (int i = 0; i < candlesNo; i++) {
    highLowArray[2 * i] = iLow(Symbol(), Period(), i);
    highLowArray[2 * i + 1] = iHigh(Symbol(), Period(), i);
  }

  for (int j = 0; j < rangeCount; j++) {
    double lowHeight = min + j * xHeight;
    double highHeight = min + j * xHeight + xHeight;
    for (int t = 0; t < 2 * candlesNo; t++) {
      if (highLowArray[t] < highHeight && highLowArray[t] > lowHeight) {
        highLowWeightArray[j]++;
      }
      if (t % 2 == 0 && highLowArray[t] < lowHeight &&
          highLowArray[t + 1] > highHeight) {
        highLowWeightArray[j]++;
      }
    }
  }

  ArrayPrint(highLowWeightArray);
}
