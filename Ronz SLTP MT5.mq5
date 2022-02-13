//+------------------------------------------------------------------+
//|                                             RoNz Auto SL n TP.mq4|
//|                              Copyright 2014-2018, Rony Nofrianto |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, drdz9876@gmail.com"
#property description   "Based from Ronz AutoSL-TP"
#property version   "1.1"
#property strict

#include <Trade\Trade.mqh> CTrade trade;
enum ENUM_CHARTSYMBOL
  {
   CurrentChartSymbol=0,//Current Chart Only
   AllOpenOrder=1//All Opened Orders
  };
enum ENUM_SLTP_MODE
  {
   Server=0,//Place SL n TP
   Client=1 //Hidden SL n TP
  };
enum ENUM_LOCKPROFIT_ENABLE
  {
   LP_DISABLE=0,//Disable
   LP_ENABLE=1//Enable
  };
enum ENUM_TRAILINGSTOP_METHOD
  {
   TS_NONE=0,//No Trailing Stop
   TS_CLASSIC=1,//Classic
   TS_STEP_DISTANCE=2,//Step Keep Distance
   TS_STEP_BY_STEP=3 //Step By Step
  };
sinput const string SLTP="";//-=[ SL & TP SETTINGS ]=-
input int   TakeProfit=550;//Take Profit
input int   StopLoss=350;//Stop Loss
input ENUM_SLTP_MODE SLnTPMode=Server;//SL & TP Mode
sinput const string Lock="";//-=[ LOCK PROFIT SETTINGS ]=-
input ENUM_LOCKPROFIT_ENABLE LockProfitEnable=LP_ENABLE;//Enable/Disable Profit Lock
input int   LockProfitAfter=100;//Target point to Lock Profit
input int   ProfitLock=60;//Profit To Lock
sinput const string Trailing="";//-=[ TRAILING STOP SETTINGS ]=-
input ENUM_TRAILINGSTOP_METHOD TrailingStopMethod=TS_CLASSIC;//Trailing Method
input int   TrailingStop=50;//Trailing Stop
input int   TrailingStep=10;//Trailing Stop Step
input int Slippage   = 10; //Slippage
input ENUM_CHARTSYMBOL  ChartSymbolSelection=AllOpenOrder;//
input bool   inpEnableAlert=false;//Enable Alert
input bool   inpEnableTest=false;//Enable Test on Strategy Tester
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SetInstantSLTP()
  {
   double SL=0, TP=0;
   double ask = 0, bid = 0, point = 0;
   int digits = 0, minstoplevel = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(PositionGetTicket(i))
         if(ChartSymbolSelection==CurrentChartSymbol && PositionGetString(POSITION_SYMBOL)!=Symbol())
            continue;
        {
         ask = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
         bid = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
         point = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT);
         digits =(int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL),SYMBOL_DIGITS);
         minstoplevel =(int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL),SYMBOL_TRADE_STOPS_LEVEL);

         double ClosePrice=0;
         int Poin=0;
         color CloseColor=clrNONE;

         //Get point
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
           {
            CloseColor=clrBlue;
            ClosePrice=bid;
            Poin=(int)((ClosePrice-PositionGetDouble(POSITION_PRICE_OPEN))/point);
           }
         else
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               CloseColor=clrRed;
               ClosePrice=ask;
               Poin=(int)((PositionGetDouble(POSITION_PRICE_OPEN)-ClosePrice)/point);
              }

         //Print("Check SL & TP : ",OrderSymbol()," SL = ",OrderStopLoss()," TP = ",OrderTakeProfit());
         //Set Server SL and TP
         if(SLnTPMode == Server)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               SL=(StopLoss>0)?NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)-((StopLoss+minstoplevel)*point),digits):0;
               TP=(TakeProfit>0)?NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)+((TakeProfit+minstoplevel)*point),digits):0;
               if(PositionGetDouble(POSITION_SL)==0.0 && PositionGetDouble(POSITION_TP)==0.0)
                 {
                  trade.PositionModify(PositionGetInteger(POSITION_TICKET),SL,TP);
                 }
               else
                  if(PositionGetDouble(POSITION_TP)==0.0)
                    {
                     trade.PositionModify(PositionGetInteger(POSITION_TICKET),PositionGetDouble(POSITION_SL),TP);
                    }
                  else
                     if(PositionGetDouble(POSITION_SL)==0.0)
                       {
                        trade.PositionModify(PositionGetInteger(POSITION_TICKET),SL,PositionGetDouble(POSITION_TP));
                       }
              }
            else
               if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
                 {
                  SL=(StopLoss>0)?NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)+((StopLoss+minstoplevel)*point),digits):0;
                  TP=(TakeProfit>0)?NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)-((TakeProfit+minstoplevel)*point),digits):0;
                  if(PositionGetDouble(POSITION_SL)==0.0 && PositionGetDouble(POSITION_TP)==0.0)
                    {
                     trade.PositionModify(PositionGetInteger(POSITION_TICKET),SL,TP);
                    }
                  else
                     if(PositionGetDouble(POSITION_TP)==0.0)
                       {
                        trade.PositionModify(PositionGetInteger(POSITION_TICKET),PositionGetDouble(POSITION_SL),TP);
                       }
                     else
                        if(PositionGetDouble(POSITION_SL)==0.0)
                          {
                           trade.PositionModify(PositionGetInteger(POSITION_TICKET),SL,PositionGetDouble(POSITION_TP));
                          }
                 }
           }
         else
            if(SLnTPMode == Client)
              {
               if((TakeProfit>0 && Poin>=TakeProfit) || (StopLoss>0 && Poin<=(-StopLoss)))
                 {
                  if(trade.PositionClose(PositionGetInteger(POSITION_TICKET),Slippage))
                    {
                     if(inpEnableAlert)
                       {
                        if(PositionGetDouble(POSITION_PROFIT)>0)
                           Alert("Closed by Virtual TP #",PositionGetInteger(POSITION_TICKET)," Profit=",PositionGetDouble(POSITION_PROFIT)," Points=",Poin);
                        if(PositionGetDouble(POSITION_PROFIT)>0)
                           Alert("Closed by Virtual SL #",PositionGetInteger(POSITION_TICKET)," Loss=",PositionGetDouble(POSITION_PROFIT)," Points=",Poin);
                       }
                    }
                 }
              }


         if(LockProfitAfter>0 && ProfitLock>0 && Poin>=LockProfitAfter)
           {
            if(Poin<=LockProfitAfter+TrailingStop)
              {
               LockProfit(PositionGetInteger(POSITION_TICKET),LockProfitAfter,ProfitLock);
              }
            else
               if(Poin>=LockProfitAfter+TrailingStop)
                 {
                  RZ_TrailingStop(PositionGetInteger(POSITION_TICKET),TrailingStop,TrailingStep,TrailingStopMethod);
                 }
           }
         else
            if(LockProfitAfter==0)
              {
               RZ_TrailingStop(PositionGetInteger(POSITION_TICKET),TrailingStop,TrailingStep,TrailingStopMethod);
              }

        }
     }

   return (false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(inpEnableTest)
      OrderTest();
   if(CalculateInstantOrders()!=0)
      SetInstantSLTP();
   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderTest()
  {
   if(!MQLInfoInteger(MQL_TESTER))
      return;
   if(CalculateInstantOrders()==0)
     {
      if(CheckMoneyForTrade("EURUSD",0.01,ORDER_TYPE_BUY) && CheckVolumeValue("EURUSD",0.01))
         trade.Buy(0.01,"EURUSD",SymbolInfoDouble("EURUSD",SYMBOL_ASK),0,0,NULL);
      if(CheckMoneyForTrade("GBPUSD",0.01,ORDER_TYPE_BUY) && CheckVolumeValue("GBPUSD",0.01))
         trade.Sell(0.01,"GBPUSD",SymbolInfoDouble("GBPUSD",SYMBOL_BID),0,0,NULL);
     }

   return;
  }

//+------------------------------------------------------------------+
bool LockProfit(ulong ticket, int Targetpoint,int Lockedpoint)
  {
   if(LockProfitEnable==false || Targetpoint==0 || Lockedpoint==0)
      return false;

   if(PositionSelectByTicket(ticket)==false)
      return false;

   double ask = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
   double bid = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
   double point = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT);
   int digits =(int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL),SYMBOL_DIGITS);
   int minstoplevel =(int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL),SYMBOL_TRADE_STOPS_LEVEL);

   double PSL=0;
   double CurrentSL=(PositionGetDouble(POSITION_SL)!=0)?PositionGetDouble(POSITION_SL):PositionGetDouble(POSITION_PRICE_OPEN);

   if(Targetpoint < Lockedpoint)
     {
      Print("Target point must be higher than Profit Lock");
      return false;
     }

   if((PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) && (bid-PositionGetDouble(POSITION_PRICE_OPEN)>=Targetpoint*point) && (CurrentSL<=PositionGetDouble(POSITION_PRICE_OPEN)))
     {
      PSL=NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)+(Lockedpoint*point),digits);
     }
   else
      if((PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) && (PositionGetDouble(POSITION_PRICE_OPEN)-ask>=Targetpoint*point) && (CurrentSL>=PositionGetDouble(POSITION_PRICE_OPEN)))
        {
         PSL=NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN)-(Lockedpoint*point),digits);
        }
      else
         return false;
   if(trade.PositionModify(ticket,PSL,PositionGetDouble(POSITION_TP)))
      return true;
   else
      return false;


   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RZ_TrailingStop(ulong ticket, int JumlahPoin,int Step=1,ENUM_TRAILINGSTOP_METHOD Method=TS_STEP_DISTANCE)
  {
   if(JumlahPoin==0)
      return false;

   if(PositionSelectByTicket(ticket)==false)
      return false;

   double ask = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
   double bid = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
   double point = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_POINT);
   int digits =(int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL),SYMBOL_DIGITS);
   int minstoplevel =(int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL),SYMBOL_TRADE_STOPS_LEVEL);
   int spread =(int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL),SYMBOL_SPREAD);

   double TSL=0;
   double CurrentSL=(PositionGetDouble(POSITION_SL)!=0)?PositionGetDouble(POSITION_SL):PositionGetDouble(POSITION_PRICE_OPEN);

   if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && (bid-PositionGetDouble(POSITION_PRICE_OPEN)>JumlahPoin*point))
     {
      //for buy limit == suspected errors come from this
      if(CurrentSL<PositionGetDouble(POSITION_PRICE_OPEN))
         CurrentSL=PositionGetDouble(POSITION_PRICE_OPEN);

      if((bid-CurrentSL)>=(JumlahPoin)*point)
        {
         switch(Method)
           {
            case TS_CLASSIC://Classic, no step
               TSL=NormalizeDouble(bid-(JumlahPoin*point),digits);
               break;
            case TS_STEP_DISTANCE://Step keeping distance
               TSL=NormalizeDouble(bid-((JumlahPoin-Step)*point),digits);
               break;
            case TS_STEP_BY_STEP://Step by step (slow)
               TSL=NormalizeDouble(CurrentSL+(Step*point),digits);
               break;
            default:
               TSL=0;
           }
        }
     }

   else
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && (PositionGetDouble(POSITION_PRICE_OPEN)-ask>JumlahPoin*point))
        {
         //for sell limit == suspected errors come from this
         if(CurrentSL>PositionGetDouble(POSITION_PRICE_OPEN))
            CurrentSL=PositionGetDouble(POSITION_PRICE_OPEN);

         if((CurrentSL-ask)>=(JumlahPoin)*point)
           {
            switch(Method)
              {
               case TS_CLASSIC://Classic
                  TSL=NormalizeDouble(ask+(JumlahPoin*point),digits);
                  break;
               case TS_STEP_DISTANCE://Step keeping distance
                  TSL=NormalizeDouble(ask+((JumlahPoin-Step)*point),digits);
                  break;
               case TS_STEP_BY_STEP://PositionGetDouble(POSITION_SL) by step (slow)
                  TSL=NormalizeDouble(CurrentSL-(Step*point),digits);
                  break;
               default:
                  TSL=0;
              }
           }
        }
   if(TSL==0)
      return false;

   if(TSL != CurrentSL)
     {
      if(trade.PositionModify(ticket,TSL,PositionGetDouble(POSITION_TP)))
         return true;
      else
         return false;
     }

   return false;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CalculateInstantOrders()
  {
   int buys=0, sells=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(PositionGetTicket(i))
         if(ChartSymbolSelection==CurrentChartSymbol && PositionGetString(POSITION_SYMBOL)!=Symbol())
            continue;
        {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
            buys++;
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
            sells++;
        }
     }
   if(buys > 0)
      return(buys);
   else
      return(-sells);

  }

//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string sym, double lots,ENUM_ORDER_TYPE type)
  {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(sym,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
//--- call of the checking function
   if(!OrderCalcMargin(type,sym,lots,price,margin))
     {
      //--- something went wrong, report and return false
      return(false);
     }
//--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      return(false);
     }
//--- checking successful
   return(true);
  }
//************************************************************************************************/
bool CheckVolumeValue(string sym, double volume)
  {

   double min_volume = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   if(volume < min_volume)
      return(false);

   double max_volume = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   if(volume > max_volume)
      return(false);

   double volume_step = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);

   int ratio = (int)MathRound(volume / volume_step);
   if(MathAbs(ratio * volume_step - volume) > 0.0000001)
      return(false);

   return(true);
  }
//+------------------------------------------------------------------+
