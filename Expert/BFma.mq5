//+------------------------------------------------------------------+
//|                                                         BFma.mq5 |
//|                                    Copyright 2021,ButterFly Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,ButterFly Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <trade/trade.mqh>
#include <generic/hashmap.mqh>
#include <generic/arraylist.mqh>


input double    StartLot=0.1;
input int TProfit=100;
input int StopL=500;
input double AtrDelta = 0.5;

input int StayPosRatioMin = 1;
input int StayPosRatioMax = 3;

input ENUM_TIMEFRAMES ATRBigTimeFrame = PERIOD_D1;  
input int ATRBigCount = 24;
input ENUM_TIMEFRAMES ATRSmallTimeFrame = PERIOD_H4;
input int ATRSmallCount = 30;

input int                Fast_MA_Period   =12;
input int                Fast_MA_Shift    =0;
input ENUM_MA_METHOD     Fast_MA_Method   =MODE_SMA;
input ENUM_APPLIED_PRICE Fast_MA_Applied  =PRICE_CLOSE;


input int                Slow_MA_Period =26;
input int                Slow_MA_Shift  =0;
input ENUM_MA_METHOD     Slow_MA_Method = MODE_SMA;
input ENUM_APPLIED_PRICE Slow_MA_Applied= PRICE_CLOSE;


input int             Factor      = 2;          
input ENUM_SERIESMODE seriesStart = MODE_LOW;   
input ENUM_SERIESMODE seriesEnd   = MODE_HIGH;  


input int                MAperiod     = 12,
                          MAshift      = 0;
input ENUM_MA_METHOD     MAmode       = MODE_SMA;
input ENUM_APPLIED_PRICE MApriceStart = PRICE_LOW;
input ENUM_APPLIED_PRICE MApriceEnd   = PRICE_HIGH;




MqlTradeRequest request;
MqlTradeResult result;
MqlTick last_tick;




CHashMap<ulong, string> AllPos;
   
   
CTrade TradeClass;

int MaFastInd;
int MaSlowInd;
int MaHighInd;
int MaLowInd;
int AtrInd;


double _MaSlow[];
double _MaFast[];
double _MaHigh[];
double _MaLow[];
double _AtrStep[];




int BuyM11Count = 0;
int SellM11Count = 0;

ulong  LastBuy11Ticket = 0;
ulong  LastSell11Ticket = 0;


double CurrentTotalProfit=0;

bool             CrossUpDone = true;
bool          CrossDownDone = true; 

bool             BuyEnterAllow = true;
bool          SellEnterAllow = true; 


int OnInit()
  {
//---
   MaFastInd = iMA(Symbol(),Period(),Fast_MA_Period,MAshift,Fast_MA_Method,Fast_MA_Applied);
   MaSlowInd = iMA(Symbol(),Period(),Slow_MA_Period,Slow_MA_Shift,Slow_MA_Method,Slow_MA_Applied);
//   
   MaHighInd = iMA(Symbol(),Period(),MAperiod,MAshift,MAmode,MApriceEnd);
   MaLowInd = iMA(Symbol(),Period(),MAperiod,Slow_MA_Shift,MAmode,MApriceStart);
   
   
   AtrInd = iATR(Symbol(),PERIOD_D1,5);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

      PositionFetch();


//     
    ArrayFree(_MaFast);

     ArraySetAsSeries(_MaFast,true);
     CopyBuffer(MaFastInd,0,0,5,_MaFast);
     
     
     ArrayFree(_MaSlow);

     ArraySetAsSeries(_MaSlow,true);
     CopyBuffer(MaSlowInd,0,0,5,_MaSlow);
     
     ArrayFree(_MaHigh);

     ArraySetAsSeries(_MaHigh,true);
     CopyBuffer(MaHighInd,0,0,Factor+1,_MaHigh);
     
     ArrayFree(_MaLow);

     ArraySetAsSeries(_MaLow,true);
     CopyBuffer(MaLowInd,0,0,Factor+1,_MaLow);
     
     
     ArrayFree(_AtrStep);

     ArraySetAsSeries(_AtrStep,true);
     CopyBuffer(AtrInd,0,0,Factor+1,_AtrStep);
     
     
  double    lowprice_i=iLow(Symbol(),Period(),iLowest(Symbol(),Period(),seriesStart,Factor,1));
  double    highprice_i=iHigh(Symbol(),Period(),iHighest(Symbol(),Period(),seriesEnd,Factor,1));
      
      
      
  //double    lowma=NormalizeDouble(iMA(NULL,0,MAperiod,MAshift,MAmode,MApriceStart,i),Digits());
  //double    highma=NormalizeDouble(iMA(NULL,0,MAperiod,MAshift,MAmode,MApriceEnd,i),Digits());

     
   //maxlowprice=MathMax(lowprice_i,maxlowprice);


     
     
//     CrossDownDone = false;
//     CrossUpDone = false;
//  
// if((_MaHigh[1] < lowprice_i) && (iClose(Symbol(),Period(),1) < iLow(Symbol(),Period(),2)))
// 
//    {
//      CrossDownDone =true;
//    }
//  if(((_MaLow[1] > highprice_i)) && (iClose(Symbol(),Period(),1) > iHigh(Symbol(),Period(),2)))
//    {
//      CrossUpDone =true;
//    }

    CrossDownDone = false;
     CrossUpDone = false;
  
 if(((_MaFast[2]-_MaSlow[2]) > 0) && ((_MaFast[1] - _MaSlow[1])<0))
 
    {
      CrossDownDone =true;
    }
  if(((_MaFast[2] - _MaSlow[2]) < 0) && ((_MaFast[1] - _MaSlow[1])> 0))
    {
      CrossUpDone =true;
    }



         string comm = "";
         SellM11Count = 0;
         BuyM11Count = 0;
         LastBuy11Ticket = 0;
         LastSell11Ticket = 0;

         ulong PTick[];
         string PStatus[];
         AllPos.CopyTo(PTick, PStatus);
         for (int t=0; t<AllPos.Count(); t++)
            {  
               comm+= ("\n" +PStatus[t]);
               if(!PositionSelectByTicket(PTick[t]))
               {  
                  AllPos.Remove(PTick[t]);
               }
               else
               {
                  
               
               string result[];
               StringSplit(PStatus[t],'*',result);
               

                 
                 if(CrossDownDone)
                 {
                 if(result[0] == "12" && result[1] == "Buy")
                   {
                     //double PosProfit = PositionGetDouble(POSITION_PROFIT);
                    
                    AllPos.TrySetValue(PTick[t], "20*Buy*"+result[2]+"*0"+"*"+result[4]);
                   }
                 if(result[0] == "20" && result[1] == "Sell")
                   {
                    AllPos.TrySetValue(PTick[t], "22*Sell*"+result[2]+"*0"+"*"+result[4]);
                   }
                 }
                 
                 if(CrossUpDone)
                 {
                 if(result[0] == "12" && result[1] == "Sell")
                  {
                     //double PosProfit = PositionGetDouble(POSITION_PROFIT);
                    
                     AllPos.TrySetValue(PTick[t], "20*Sell*"+result[2]+"*0"+"*"+result[4]);
                  }
                 if(result[0] == "20" && result[1] == "Buy")
                   {
                    AllPos.TrySetValue(PTick[t], "22*Buy*"+result[2]+"*0"+"*"+result[4]);
                   }
                 }
                 
                if(result[0] == "22" )
                 {
                    double PosProfit = PositionGetDouble(POSITION_PROFIT);
                    
                    string StepsStringSplit[];
                    StringSplit(result[2],'$',StepsStringSplit);
                    
                 if(PosProfit>=  ((double)StepsStringSplit[0] * StayPosRatioMin * ((double)StepsStringSplit[1]/Point())/(-10)))
                 //if(PosProfit>=  20)
                     {
                        TradeClass.PositionClose(PTick[t]);
                         AllPos.Remove(PTick[t]);
                     }
                    
                   // double trtrtrt = (double)StepsStringSplit[0] * StayPosRatioMax * ((double)StepsStringSplit[1]/Point())*10;
                     if(PosProfit<((double)StepsStringSplit[0] * StayPosRatioMax * ((double)StepsStringSplit[1]/Point())/(-10)*2))
                     {
                        //TradeClass.PositionClose(PTick[t]);
                        // AllPos.Remove(PTick[t]);
                        MqlTradeResult Newres ;
                        Newres =  OrderPlace(result[1],33,0,StartLot*((double)StepsStringSplit[0] * StayPosRatioMax),"");
                        
                        AllPos.TrySetValue(PTick[t], "23*"+result[1]+"*"+result[2]+"*"+Newres.deal+"*"+result[4]);
                     }
                     
                 }
               
               if(result[0] == "23")
                 {
                  string StepsStringSplit[];
                    StringSplit(result[2],'$',StepsStringSplit);
                 
                   double PosProfit = PositionGetDouble(POSITION_PROFIT);
                   
                   PositionSelectByTicket((ulong)result[3]);
                   
                   double AlterPosProfit = PositionGetDouble(POSITION_PROFIT);
                   
                    if(PosProfit+AlterPosProfit>0)
                     {
                        TradeClass.PositionClose(PTick[t]);
                        
                        TradeClass.PositionClose((ulong)result[3]);
                        
                         AllPos.Remove(result[3]);
                         AllPos.Remove(PTick[t]);
                         
                     }
                    if(PosProfit< 2*((double)StepsStringSplit[0] * StayPosRatioMax * ((double)StepsStringSplit[1]/Point())/(-10)))
                     {
                        MqlTradeResult Newres ;
                        Newres =  OrderPlace(result[1],44,0,StartLot*((double)StepsStringSplit[0] * StayPosRatioMax),"");
                        
                        AllPos.TrySetValue(PTick[t], "24*"+result[1]+"*"+result[2]+"*"+result[3]+"*"+result[4]);
                        AllPos.TrySetValue((ulong)result[3], "34*"+result[1]+"*"+result[2]+"*"+Newres.deal+"*"+result[4]);
                         
                     }
                }
                
                
              if(result[0] == "24")
                 {
                   double PosProfit = PositionGetDouble(POSITION_PROFIT);
                   
                   PositionSelectByTicket((ulong)result[3]);
                   
                   double AlterPosProfit = PositionGetDouble(POSITION_PROFIT);
                   
                   string PosStatus;
                   AllPos.TryGetValue((ulong)result[3],PosStatus);
                   
                   string Posresult[];
                   StringSplit(PosStatus,'*',Posresult);
               
                   PositionSelectByTicket(Posresult[3]);
                   
                   double SecAlterPosProfit = PositionGetDouble(POSITION_PROFIT);
                   
                    if(PosProfit+AlterPosProfit+SecAlterPosProfit>0)
                     {
                        TradeClass.PositionClose(PTick[t]);
                        
                        TradeClass.PositionClose((ulong)result[3]);
                        
                        TradeClass.PositionClose((ulong)Posresult[3]);
                        
                         AllPos.Remove(result[3]);
                         AllPos.Remove(PTick[t]);
                         AllPos.Remove(Posresult[3]);
                         
                     }
                }
               }
            }
         
            Comment(comm);


 


    if(CrossDownDone)
    if(SellEnterAllow)
     {
         
        

          
      
      MqlTradeResult ordres2 ;
      
    string StepString = CalcStep("Sell");
    string StepStringSplit[];
    StringSplit(StepString,'$',StepStringSplit);
           
   
         
       ordres2=     OrderPlace("Sell",12,0,StartLot,StepString);

         if(ordres2.deal != 0)
         {
            BuyEnterAllow = true;
            SellEnterAllow = false; 
         }          
         
         
      } 
         
   
     if( CrossUpDone)
     if(BuyEnterAllow)
     {     
     
              
       
        
       
 
  MqlTradeResult ordres2 ;
    
    string StepString = CalcStep("Buy");
    string StepStringSplit[];
    StringSplit(StepString,'$',StepStringSplit);
    
           
   
         
     ordres2=    OrderPlace("Buy",12,0,StartLot,StepString);
         
       if(ordres2.deal != 0)
         {
            BuyEnterAllow = false;
            SellEnterAllow = true;
         }  
         
        }
      
   
  }

MqlTradeResult OrderPlace(string PosType,int magicNo,double CalcTP,double Lot,string orderComment)
{
   if(PosType == "Buy")
     {
       SymbolInfoTick(_Symbol,last_tick);

                                    ZeroMemory(request);
                                    ZeroMemory(result);

                                    request.action=TRADE_ACTION_DEAL;
                                    request.magic=magicNo;
                                    request.comment = orderComment;
                                    request.symbol=_Symbol;
                                    Lot = (MathFloor(Lot * 100)) / 100;
                                    Lot = NormalizeDouble(Lot, 2);
                                    request.volume= Lot;
                                    if(magicNo == 11)
                                    {
                                    //request.sl=last_tick.bid-(StopL*0.00001);
                                    request.tp=last_tick.ask+CalcTP;
                                    }

                                    request.type=ORDER_TYPE_BUY;

                                    request.price=last_tick.ask;


                                    OrderSend(request,result);
     }
   if(PosType == "Sell")
     {
                         SymbolInfoTick(_Symbol,last_tick);

                                    ZeroMemory(request);
                                    ZeroMemory(result);

                                    request.action=TRADE_ACTION_DEAL;
                                    request.magic=magicNo;
                                    request.comment = orderComment;
                                    request.symbol=_Symbol;
                                    Lot = (MathFloor(Lot * 100)) / 100;
                                    Lot = NormalizeDouble(Lot, 2);
                                    request.volume= Lot;
                                    if(magicNo == 11)
                                    {
                                    //request.sl=last_tick.bid+(StopL*0.00001);
                                    request.tp=last_tick.ask-CalcTP;
                                    }

                                    request.type=  ORDER_TYPE_SELL;

                                    request.price=last_tick.bid;


                                    OrderSend(request,result);
     }
     return result;
}

string CalcStep(string PosType)
{
   SymbolInfoTick(Symbol(),last_tick);
   
   return "2$"+(string)(_AtrStep[1]*AtrDelta);
   
   
//   
//   if(PosType == "Buy")
//     {
//       double LastLow = iLow(Symbol(),Period(),1);
//      for(int j=1;j<=35+1;j++)
//      {
//         LastLow = MathMin(LastLow,iLow(Symbol(),Period(),j));
//      
//      }   
//      return "2$"+(string)MathAbs(last_tick.bid-LastLow);
//     }
//   else
//     {
//       double LastHigh = iHigh(Symbol(),Period(),1);
//      for(int j=1;j<=35+1;j++)
//      {
//         LastHigh = MathMax(LastHigh,iHigh(Symbol(),Period(),j));
//      
//      }   
//      return "2$"+(string)MathAbs(last_tick.ask-LastHigh);
//    }
   
   
   
   
//   if(PosType == "Sell")
//     {
//      int i = 2;
//     bool FindLastHigh = false;
//     double LastHigh ;
//     while(!FindLastHigh)
//     {
//      if(iHigh(Symbol(),Period(),i)>iHigh(Symbol(),Period(),i+1) && iHigh(Symbol(),Period(),i)>iHigh(Symbol(),Period(),i-1))
//        {
//         if(last_tick.bid<iHigh(Symbol(),Period(),i))
//         {
//         FindLastHigh = true;
//         LastHigh = iHigh(Symbol(),Period(),i);
//         }
//        }
//        i++;
//     }    
//     
//     
//     double LastHighDist = LastHigh-last_tick.bid;
//     
    
    
//    double SumATRBig = 0;
//    double SumATRSmall = 0;
//        
//    for(int j=1;j<ATRBigCount+1;j++)
//     {
//      SumATRBig += MathAbs(iOpen(Symbol(),ATRBigTimeFrame,j) - iClose(Symbol(),ATRBigTimeFrame,j));
//      
//     }    
//     
//    for(int k=1;k<ATRSmallCount+1;k++)
//     {
//      SumATRSmall += MathAbs(iOpen(Symbol(),ATRSmallTimeFrame,k) - iClose(Symbol(),ATRSmallTimeFrame,k));
//      
//     }    
//     
//     return    "2$"+((string)((((3*(SumATRBig/ATRBigCount)) - (SumATRSmall/ATRSmallCount)))));
     
       //  Comment((string)SumATRBig+"^^^^^"+(string)SumATRSmall+"^^^^^"+(string)LastHighDist+"^^^^^");
//     if ( (((3*(SumATRBig/ATRBigCount)) - (SumATRSmall/ATRSmallCount)))  > LastHighDist)
//           {
//            return "2$"+ (string)MathAbs(LastHighDist);
//           }
//           else
//           {
//              return "1$"+ (string)MathAbs(LastHighDist);
//           }
//      
//      
//     }
//     else
//       {
//             int i = 2;
//     bool FindLastLow = false;
//     double LastLow = 0 ;
//     while(!FindLastLow)
//     {
//      if(iLow(Symbol(),Period(),i)<iLow(Symbol(),Period(),i+1) && iLow(Symbol(),Period(),i)<iLow(Symbol(),Period(),i-1))
//        {
//         if(last_tick.bid>iLow(Symbol(),Period(),i))
//         {
//         FindLastLow = true;
//         LastLow = iLow(Symbol(),Period(),i);
//         }
//        }
//        i++;
//     }    
//     
// 
//     double LastLowDist = last_tick.bid-LastLow;
//     
//    
//    
//    double SumATRBig = 0;
//    double SumATRSmall = 0;
//        
//    for(int j=1;j<ATRBigCount+1;j++)
//     {
//      SumATRBig += MathAbs(iOpen(Symbol(),ATRBigTimeFrame,j) - iClose(Symbol(),ATRBigTimeFrame,j));
//      
//     }    
//     
//    for(int k=1;k<ATRSmallCount+1;k++)
//     {
//      SumATRSmall += MathAbs(iOpen(Symbol(),ATRSmallTimeFrame,k) - iClose(Symbol(),ATRSmallTimeFrame,k));
//      
//     }    
//         //Comment((string)SumATRBig+"^^^^^"+(string)SumATRSmall+"^^^^^"+(string)LastHighDist+"^^^^^");
//         if ( (((3*(SumATRBig/ATRBigCount)) - (SumATRSmall/ATRSmallCount)))  > LastLowDist)
//           {
//            return "2$"+ (string)MathAbs(LastLowDist);
//           }
//           else
//           {
//              return "1$"+ (string)MathAbs(LastLowDist);
//           }
//         
//       }
}

void PositionFetch()
{
  
   
    CurrentTotalProfit=0;
  
   int positions=PositionsTotal();
   for(int i=0;i<positions;i++)
     {
      ResetLastError();
      ulong ticket=PositionGetTicket(i);
      if(ticket!=0)// if the order was successfully copied into the cache, work with it
        {
         
         double price_open=PositionGetDouble(POSITION_PRICE_OPEN);
         //datetime time_setup=PositionGetInteger(POSITION_TIME_SETUP);
         string symbol=PositionGetString(POSITION_SYMBOL);
         string ordcomment =PositionGetString(POSITION_COMMENT);
         long magic_number=PositionGetInteger(POSITION_MAGIC);
         double volume=PositionGetDouble(POSITION_VOLUME);
         ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         if( !AllPos.ContainsKey(ticket) )
           {
            if(type==POSITION_TYPE_BUY)
              AllPos.Add(ticket,((string)magic_number+"*"+"Buy"+"*"+ordcomment+"*"+"0"+"*"+price_open));
            if(type==POSITION_TYPE_SELL)
            AllPos.Add(ticket,((string)magic_number+"*"+"Sell"+"*"+ordcomment+"*"+"0"+"*"+price_open));
           }


        }


     }
}

