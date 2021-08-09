
MqlTradeResult CreateOrder(
    string symbol,
    // TODO: need to be changed to ENUM_ORDER_TYPE after refactoring main file
    string orderType,
    int magic,
    string comment,
    double lot,
    double price,
    double tp = 0,
    double sl = 0)
{
  MqlTradeRequest request;
  MqlTradeResult result;
  double volume = 0.0;

  // TODO: need to be removed after orderType changed to ENUM_ORDER_TYPE
  string localOrderType = orderType == "Buy" ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

  ZeroMemory(request);
  ZeroMemory(result);

  request.action = TRADE_ACTION_DEAL;
  request.magic = magic;
  request.comment = comment;
  request.symbol = symbol;
  request.type = localOrderType;
  volume = (MathFloor(lot * 100)) / 100;
  volume = NormalizeDouble(volume, 2);
  request.volume = volume;
  request.price = price;
  request.tp = tp;
  request.sl = sl;

  OrderSend(request, result);

  return result;
}
