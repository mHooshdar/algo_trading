struct SupportResistanceRange {
  double low;
  double high;
  int weight;
};

void SupportResistance(double rangeSize, int candlesCount, SupportResistanceRange& rangeArray[]) {
  //TODO: create struct for data array
  double dataArray[];

  double min = iLow(Symbol(), Period(),
                    iLowest(Symbol(), Period(), MODE_LOW, candlesCount, 0));
  double max = iHigh(Symbol(), Period(),
                     iHighest(Symbol(), Period(), MODE_HIGH, candlesCount, 0));

  int rangeCount = MathCeil((max - min) / rangeSize);

  ArrayResize(dataArray, 2 * candlesCount);
  ArrayResize(rangeArray, rangeCount);

  for (int i = 0; i < candlesCount; i++) {
    dataArray[2 * i] = iLow(Symbol(), Period(), i);
    dataArray[2 * i + 1] = iHigh(Symbol(), Period(), i);
  }

  for (int j = 0; j < rangeCount; j++) {
    double rangeLow = min + j * rangeSize;
    double rangeHigh = min + j * rangeSize + rangeSize;
    rangeArray[j].low = rangeLow;
    rangeArray[j].high = rangeHigh;

    for (int t = 0; t < 2 * candlesCount; t++) {
      if (dataArray[t] < rangeHigh && dataArray[t] > rangeLow) {
        rangeArray[j].weight++;
      }
      if (t % 2 == 0 && dataArray[t] < rangeLow &&
          dataArray[t + 1] > rangeHigh) {
        rangeArray[j].weight++;
      }
    }
  }

  //TODO: return sorted array
}