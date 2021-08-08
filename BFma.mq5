#property copyright "Copyright 2021,ButterFly Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

#include <trade/trade.mqh>
#include <generic/hashmap.mqh>
#include <generic/arraylist.mqh>
#include <CreateOrder.mqh>

input double StartLot = 0.1;
input int TProfit = 100;
input int StopL = 500;
input bool PositionCloseWithMaCross = true;

input ENUM_TIMEFRAMES ATRBigTimeFrame = PERIOD_D1;
input int ATRBigCount = 24;
input ENUM_TIMEFRAMES ATRSmallTimeFrame = PERIOD_D1;
input int ATRSmallCount = 30;

input int Fast_MA_Period = 12;
input int Fast_MA_Shift = 0;
input ENUM_MA_METHOD Fast_MA_Method = MODE_SMA;
input ENUM_APPLIED_PRICE Fast_MA_Applied = PRICE_CLOSE;

input int Slow_MA_Period = 26;
input int Slow_MA_Shift = 0;
input ENUM_MA_METHOD Slow_MA_Method = MODE_SMA;
input ENUM_APPLIED_PRICE Slow_MA_Applied = PRICE_CLOSE;

MqlTick last_tick;

CHashMap<ulong, string> AllPos;

CTrade TradeClass;

int MaFastInd;
int MaSlowInd;

double _MaSlow[];
double _MaFast[];

int BuyM11Count = 0;
int SellM11Count = 0;

ulong LastBuy11Ticket = 0;
ulong LastSell11Ticket = 0;

double CurrentTotalProfit = 0;

bool CrossUpDone = true;
bool CrossDownDone = true;

bool BuyEnterAllow = true;
bool SellEnterAllow = true;

int OnInit()
{
  MaFastInd = iMA(Symbol(), Period(), Fast_MA_Period, Fast_MA_Shift, Fast_MA_Method, Fast_MA_Applied);
  MaSlowInd = iMA(Symbol(), Period(), Slow_MA_Period, Slow_MA_Shift, Slow_MA_Method, Slow_MA_Applied);

  return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick()
{
  PositionFetch();

  ArrayFree(_MaFast);

  ArraySetAsSeries(_MaFast, true);
  CopyBuffer(MaFastInd, 0, 0, 5, _MaFast);

  ArrayFree(_MaSlow);

  ArraySetAsSeries(_MaSlow, true);
  CopyBuffer(MaSlowInd, 0, 0, 5, _MaSlow);

  CrossDownDone = false;
  CrossUpDone = false;

  if (((_MaFast[2] - _MaSlow[2]) > 0) && ((_MaFast[1] - _MaSlow[1]) < 0))
  {
    CrossDownDone = true;
  }
  if (((_MaFast[2] - _MaSlow[2]) < 0) && ((_MaFast[1] - _MaSlow[1]) > 0))
  {
    CrossUpDone = true;
  }

  string comm = "";
  SellM11Count = 0;
  BuyM11Count = 0;
  LastBuy11Ticket = 0;
  LastSell11Ticket = 0;

  ulong PTick[];
  string PStatus[];
  AllPos.CopyTo(PTick, PStatus);
  for (int t = 0; t < AllPos.Count(); t++)
  {
    comm += ("\n" + PStatus[t]);
    if (!PositionSelectByTicket(PTick[t]))
    {
      AllPos.Remove(PTick[t]);
    }
    else
    {

      string result[];
      StringSplit(PStatus[t], '*', result);

      if (result[1] == "Sell" && result[0] == "11")
      {
        SellM11Count++;
        LastBuy11Ticket = PTick[t];
      }

      if (result[1] == "Buy" && result[0] == "11")
      {
        BuyM11Count++;
        LastSell11Ticket = PTick[t];
      }

      if (CrossDownDone)
      {
        if (result[0] == "12" && result[1] == "Buy")
        {
          AllPos.TrySetValue(PTick[t], "20*Buy*0*0");
        }
        if (result[0] == "20" && result[1] == "Sell")
        {
          AllPos.TrySetValue(PTick[t], "22*Sell*0*0");
        }
      }

      if (CrossUpDone)
      {
        if (result[0] == "12" && result[1] == "Sell")
        {
          AllPos.TrySetValue(PTick[t], "20*Sell*0*0");
        }
        if (result[0] == "20" && result[1] == "Buy")
        {
          AllPos.TrySetValue(PTick[t], "22*Buy*0*0");
        }
      }

      if (result[0] == "22")
      {
        double PosProfit = PositionGetDouble(POSITION_PROFIT);

        if (PosProfit >= -30)
        {
          TradeClass.PositionClose(PTick[t]);
          AllPos.Remove(PTick[t]);
        }

        if (PosProfit < -60)
        {
          MqlTradeResult Newres;
          Newres = localCreateOrder(result[1], 33, 0.6);

          AllPos.TrySetValue(PTick[t], "23*" + result[1] + "*0*" + Newres.deal);
        }
      }

      if (result[0] == "23")
      {
        double PosProfit = PositionGetDouble(POSITION_PROFIT);

        PositionSelectByTicket((ulong)result[3]);

        double AlterPosProfit = PositionGetDouble(POSITION_PROFIT);

        if (PosProfit + AlterPosProfit > 0)
        {
          TradeClass.PositionClose(PTick[t]);

          TradeClass.PositionClose((ulong)result[3]);

          AllPos.Remove(result[3]);
          AllPos.Remove(PTick[t]);
        }
      }
    }
  }

  Comment(comm);

  if (CrossDownDone)
    if (SellEnterAllow)
    {

      ulong PTick[];
      string PStatus[];
      AllPos.CopyTo(PTick, PStatus);
      for (int t = 0; t < AllPos.Count(); t++)
      {
        PositionSelectByTicket(PTick[t]);
        string result[];
        ArrayFree(result);
        StringSplit(PStatus[t], '*', result);

        if (result[0] == "11" && result[1] == "Buy")
        {
          TradeClass.PositionClose(PTick[t]);
          AllPos.Remove(PTick[t]);
        }

        //
        //                 if(result[0] == "12" && result[1]=="Sell")
        //                 {
        //                    AllPos.TrySetValue(PTick[t], "22*Sell*0*0");
        //                 }
        //
        //               if(result[0] == "22" && result[1]=="Sell")
        //                 {
        //                    double PosProfit = PositionGetDouble(POSITION_PROFIT);
        //
        //                    if(PosProfit>=-30)
        //                     {
        //                        TradeClass.PositionClose(PTick[t]);
        //                         AllPos.Remove(PTick[t]);
        //                     }
        //
        //                     if(PosProfit<-60)
        //                     {
        //                        MqlTradeResult Newres ;
        //                        Newres =  OrderPlace("Sell",33,0,0.6);
        //
        //                        AllPos.TrySetValue(PTick[t], "23*Sell*0*"+Newres.deal);
        //                     }
        //                }
      }

      MqlTradeResult ordres1;
      MqlTradeResult ordres2;

      ordres1 = localCreateOrder("Sell", 11, StartLot);
      ordres2 = localCreateOrder("Sell", 12, StartLot);

      if (ordres1.deal != 0 && ordres2.deal != 0)
      {
        BuyEnterAllow = true;
        SellEnterAllow = false;
      }
    }

  if (CrossUpDone)
    if (BuyEnterAllow)
    {

      ulong PTick[];
      string PStatus[];
      AllPos.CopyTo(PTick, PStatus);
      for (int t = 0; t < AllPos.Count(); t++)
      {
        PositionSelectByTicket(PTick[t]);
        string result[];
        ArrayFree(result);
        StringSplit(PStatus[t], '*', result);

        if (result[0] == "11" && result[1] == "Sell")
        {
          TradeClass.PositionClose(PTick[t]);
          AllPos.Remove(PTick[t]);
        }

        //               if(result[0] == "12" && result[1]=="Buy")
        //                 {
        //                    AllPos.TrySetValue(PTick[t], "22*Buy*0*0");
        //                 }
        //
        //               if(result[0] == "22" && result[1]=="Buy")
        //                 {
        //                    double PosProfit = PositionGetDouble(POSITION_PROFIT);
        //
        //                    if(PosProfit>=-30)
        //                     {
        //                        TradeClass.PositionClose(PTick[t]);
        //                         AllPos.Remove(PTick[t]);
        //                     }
        //
        //                     if(PosProfit<-60)
        //                     {
        //                        MqlTradeResult Newres ;
        //                        Newres =  OrderPlace("Buy",33,0,0.6);
        //                        AllPos.TrySetValue(PTick[t], "23*Buy*0*"+Newres.deal);
        //                     }
        //                }
      }

      MqlTradeResult ordres1;
      MqlTradeResult ordres2;

      ordres1 = localCreateOrder("Buy", 11, StartLot);
      ordres2 = localCreateOrder("Buy", 12, StartLot);

      if (ordres1.deal != 0 && ordres2.deal != 0)
      {
        BuyEnterAllow = false;
        SellEnterAllow = true;
      }
    }
}

double CalcTP(string PosType)
{
  SymbolInfoTick(Symbol(), last_tick);
  if (PosType == "Sell")
  {
    int i = 2;
    bool FindLastHigh = false;
    double LastHigh;
    while (!FindLastHigh)
    {
      if (iHigh(Symbol(), Period(), i) > iHigh(Symbol(), Period(), i + 1) && iHigh(Symbol(), Period(), i) > iHigh(Symbol(), Period(), i - 1))
      {
        if (last_tick.bid < iHigh(Symbol(), Period(), i))
        {
          FindLastHigh = true;
          LastHigh = iHigh(Symbol(), Period(), i);
        }
      }
      i++;
    }

    double LastHighDist = LastHigh - last_tick.bid;

    double SumATRBig = 0;
    double SumATRSmall = 0;

    for (int j = 1; j < ATRBigCount + 1; j++)
    {
      SumATRBig += MathAbs(iOpen(Symbol(), ATRBigTimeFrame, j) - iClose(Symbol(), ATRBigTimeFrame, j));
    }

    for (int k = 1; k < ATRSmallCount + 1; k++)
    {
      SumATRSmall += MathAbs(iOpen(Symbol(), ATRSmallTimeFrame, k) - iClose(Symbol(), ATRSmallTimeFrame, k));
    }
    //  Comment((string)SumATRBig+"^^^^^"+(string)SumATRSmall+"^^^^^"+(string)LastHighDist+"^^^^^");
    if ((((3 * (SumATRBig / ATRBigCount)) - (SumATRSmall / ATRSmallCount))) > LastHighDist)
    {
      return MathAbs(LastHighDist);
    }
    else
    {
      return MathAbs(2 * LastHighDist);
    }
  }
  else
  {
    int i = 2;
    bool FindLastLow = false;
    double LastLow = 0;
    while (!FindLastLow)
    {
      if (iLow(Symbol(), Period(), i) < iLow(Symbol(), Period(), i + 1) && iLow(Symbol(), Period(), i) < iLow(Symbol(), Period(), i - 1))
      {
        if (last_tick.bid > iLow(Symbol(), Period(), i))
        {
          FindLastLow = true;
          LastLow = iLow(Symbol(), Period(), i);
        }
      }
      i++;
    }

    double LastLowDist = last_tick.bid - LastLow;

    double SumATRBig = 0;
    double SumATRSmall = 0;

    for (int j = 1; j < ATRBigCount + 1; j++)
    {
      SumATRBig += MathAbs(iOpen(Symbol(), ATRBigTimeFrame, j) - iClose(Symbol(), ATRBigTimeFrame, j));
    }

    for (int k = 1; k < ATRSmallCount + 1; k++)
    {
      SumATRSmall += MathAbs(iOpen(Symbol(), ATRSmallTimeFrame, k) - iClose(Symbol(), ATRSmallTimeFrame, k));
    }
    //Comment((string)SumATRBig+"^^^^^"+(string)SumATRSmall+"^^^^^"+(string)LastHighDist+"^^^^^");
    if ((((3 * (SumATRBig / ATRBigCount)) - (SumATRSmall / ATRSmallCount))) > LastLowDist)
    {
      return MathAbs(LastLowDist);
    }
    else
    {
      return MathAbs(2 * LastLowDist);
    }
  }
}

void PositionFetch()
{

  CurrentTotalProfit = 0;

  int positions = PositionsTotal();
  for (int i = 0; i < positions; i++)
  {
    ResetLastError();
    ulong ticket = PositionGetTicket(i);
    if (ticket != 0) // if the order was successfully copied into the cache, work with it
    {

      double price_open = PositionGetDouble(POSITION_PRICE_OPEN);
      //datetime time_setup=PositionGetInteger(POSITION_TIME_SETUP);
      string symbol = PositionGetString(POSITION_SYMBOL);
      long magic_number = PositionGetInteger(POSITION_MAGIC);
      double volume = PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if (!AllPos.ContainsKey(ticket))
      {
        if (type == POSITION_TYPE_BUY)
          AllPos.Add(ticket, ((string)magic_number + "*" + "Buy" + "*" + "0" + "*" + "0"));
        if (type == POSITION_TYPE_SELL)
          AllPos.Add(ticket, ((string)magic_number + "*" + "Sell" + "*" + "0" + "*" + "0"));
      }
    }
  }
}

MqlTradeResult localCreateOrder(string orderType, int magic, double lot)
{
  double price = 0;
  double tp = 0;
  double sl = 0;

  SymbolInfoTick(_Symbol, last_tick);

  if (orderType == "Buy")
  {
    price = last_tick.ask;
    if (magic == 11)
      tp = last_tick.ask + CalcTP(orderType);
  }
  else if (orderType == "Sell")
  {
    price = last_tick.bid;
    if (magic == 11)
      tp = last_tick.ask - CalcTP(orderType);
  }

  return CreateOrder(_Symbol, orderType, magic, (string)magic, lot, price, tp, sl);
}