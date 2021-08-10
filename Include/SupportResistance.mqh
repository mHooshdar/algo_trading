int[] SupportResistance(double rangeSize, int candlesCount) {
  double highLowArray[];
  double highLowWeightArray[];

  double min = iLow(Symbol(), Period(),
                    iLowest(Symbol(), Period(), MODE_LOW, candlesNo, 0));
  double max = iHigh(Symbol(), Period(),
                     iHighest(Symbol(), Period(), MODE_HIGH, candlesNo, 0));

  int rangeCount = MathCeil((max - min) / xHeight);
  Print(rangeCount);

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
    }
  }

  return (highLowWeightArray);
}