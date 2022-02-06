//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2021"
#property link        "drdz9876@gmail.com"
#property version     "2.0"
#include <Trade\PositionInfo.mqh> CPositionInfo     m_position;
#include <Trade\Trade.mqh> CTrade trade;
enum MartinMode
  {
   Multiply,        //Multiply
   Increment        //Addition
  };
enum AveragingMode
  {
   AverageDown,      //Average Down
   AverageUp,        //Average Up
   None              //No Average
  };
sinput   const string Mm="";//-=[ Money Management Settings ]=-
input    double                  iStartLots        = 0.01;        //Constant lot
sinput   const string SLTP="";//-=[ SL-TP Settings ]=-
input    double                  StopLoss          = 20;       //StopLoss
input    double                  TakeProfit        = 20;       //TakeProfit
sinput   const string Time="";//-=[ Time Settings ]=-
input    int                     StartTime       = 3;       // Opening Time (Server Time)
input    int                     EndTime         = 18;      // Last Open Position Time (Server Time)
sinput   const string signal="";//-=[ Signal Settings ]=-
input    ENUM_TIMEFRAMES         Period1         = PERIOD_H1;  //Entry Signal Timeframe
sinput   const string Indicator="";//-=[ Indicator Settings ]=-
input    int                     bar             = 3;         //Bars Calculated
input    ENUM_TIMEFRAMES         ATRTF           = PERIOD_CURRENT;  //ATR Timeframe
input    int                     ATRPeriod       = 14;         //ATR Period
sinput   const string Martin="";//-=[ Martingale Settings ]=-
input    AveragingMode           AverageMode              = AverageDown;   //Choose Averaging Mode
input    MartinMode              MartinsMode              = Multiply;      //Choose Averaging/Martingale Mode
input    double                  LotMultiplier            = 1.5;           // Lot Multiplier
input    double                  LotIncrement             = 0.1;           // Additional Lot for Averaging
input    double                  GridMultiplier           = 0.75;          // Grid Multiplier (in ATR)
input    int                     MaxAverageOrders         = 3;             // Max Average Orders
sinput   const string Other="";//-=[ Other Settings ]=-
input    bool                    TradeAtNewBar     = false;          //Trade at New Bar
input    int                     iMagicNumber      = 227;            // Magic Number
input    int                     iSlippage         = 10;             // Slippage/Deviation
input    int                     TrailingStart     = 100;            // Distance from Start Price (for Average Up Only)
input    int                     TrailingStop      = 50;             // Trailing Stop (in Points)
input    int                     TrailingStep      = 30;             // Trailing Step (in Points)
input    string                  Commentary        = "Basic Martingale EA";  // Order Comment
input    bool                    ChartInfo         = true;           //Display Chart Info
//---
double PipValue=1;    // this variable is here to support 5-digit brokers
int TEMA, ATR;
//************************************************************************************************/
//*                                                                                              */
//************************************************************************************************/
int OnInit(void)
  {
   Comment("");
   trade.LogLevel(LOG_LEVEL_ERRORS);
   trade.SetExpertMagicNumber(iMagicNumber);
   trade.SetDeviationInPoints(iSlippage);
   trade.SetMarginMode();
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetTypeFillingBySymbol(Symbol());
//Indicators
   TEMA = iTEMA(Symbol(),Period(),50,0,PRICE_CLOSE);
   if(TEMA == INVALID_HANDLE)
     {
      Print("Errors for Create TEMA Indicator ",GetLastError());
      return(INIT_FAILED);
     }
   ATR = iATR(Symbol(),ATRTF,ATRPeriod);
   if(ATR == INVALID_HANDLE)
     {
      Print("Errors for Create ATR Indicator ",GetLastError());
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(ChartID(),"Background");
   ObjectDelete(ChartID(),"AccNumber");
   ObjectDelete(ChartID(),"AccLeverage");
   ObjectDelete(ChartID(),"AccBalance");
   ObjectDelete(ChartID(),"AccEquity");
   ObjectDelete(ChartID(),"AccMargin");
   ObjectDelete(ChartID(),"AccFMargin");
   ObjectDelete(ChartID(),"AccProfit");
   ObjectDelete(ChartID(),"Signal1");
   return;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool createBackground(string name)
  {
   ObjectCreate(ChartID(), name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(ChartID(), name, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, 10);
   ObjectSetInteger(ChartID(), name, OBJPROP_XSIZE, 300);
   ObjectSetInteger(ChartID(), name, OBJPROP_YSIZE, 300);
   ObjectSetInteger(ChartID(), name, OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(ChartID(), name, OBJPROP_BORDER_COLOR, clrWhite);
   ObjectSetInteger(ChartID(), name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, 0);
   ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
   ObjectSetInteger(ChartID(), name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(ChartID(), name, OBJPROP_HIDDEN, true);
   return (true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool createObject(string name,string text,int x,int y,int size, int clr)
  {
   ObjectCreate(ChartID(),name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(ChartID(),name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(ChartID(),name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(ChartID(),name, OBJPROP_YDISTANCE, y);
   ObjectSetString(ChartID(),name,OBJPROP_TEXT, text);
   ObjectSetInteger(ChartID(),name,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(ChartID(),name,OBJPROP_COLOR,clr);

   return (true);
  }

//+------------------------------------------------------------------+
void OnTick(void)
  {
   if(ChartInfo)
     {
      createBackground("Background");
      createObject("AccNumber","Account Number: "+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN),0),15,20,16,clrRed);
      createObject("AccLeverage","Account Leverage: "+IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE),2),15,45,10,clrWhite);
      createObject("AccBalance","Account Balance: "+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2),15,65,10,clrWhite);
      createObject("AccEquity","Account Equity: "+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2),15,85,10,clrWhite);
      createObject("AccMargin","Account Margin: "+DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN),2),15,105,10,clrWhite);
      createObject("AccFMargin","Account Free Margin: "+DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE),2),15,125,10,clrWhite);
      createObject("AccProfit","Floating P/L: "+DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT),2),15,155,16,clrRed);
      createObject("Signal1",EnumToString(Period1)+" Entry Signal: "+Sig(Symbol(),Period1),15,185,10,clrRed);
     }
   if(!ChartInfo)
     {
      ObjectDelete(ChartID(),"Background");
      ObjectDelete(ChartID(),"AccNumber");
      ObjectDelete(ChartID(),"AccLeverage");
      ObjectDelete(ChartID(),"AccBalance");
      ObjectDelete(ChartID(),"AccEquity");
      ObjectDelete(ChartID(),"AccMargin");
      ObjectDelete(ChartID(),"AccFMargin");
      ObjectDelete(ChartID(),"AccProfit");
      ObjectDelete(ChartID(),"Signal1");
     }

   Trade(Symbol());

   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trade(string sym)
  {
   if(!RefreshRates(sym))
     {
      Print("Can't Load "+sym+" Data");
      return;
     }

   double ask = SymbolInfoDouble(sym,SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym,SYMBOL_BID);
   double points = SymbolInfoDouble(sym,SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(sym,SYMBOL_DIGITS);

   if(digits == 3 || digits == 5)
      PipValue = 10;

   double
   BuyPriceMax=0,BuyPriceMin=0,BuyPriceMaxLot=0,BuyPriceMinLot=0,
   SelPriceMin=0,SelPriceMax=0,SelPriceMinLot=0,SelPriceMaxLot=0;

   ulong
   BuyPriceMaxTic=0,BuyPriceMinTic=0,SelPriceMaxTic=0,SelPriceMinTic=0;

   ulong tkb= 0,tks=0;

   double
   op=0,lt=0,tpb=0,tps=0, slb=0,sls=0;

   int b=0,s=0, Opens = 0;

   for(int k=PositionsTotal()-1; k>=0; k--)
     {
      if(m_position.SelectByIndex(k))
        {
         if(m_position.Symbol()==sym)
           {
            if(m_position.Magic()==iMagicNumber)
              {
               op=NormalizeDouble(m_position.PriceOpen(),digits);
               lt=NormalizeDouble(m_position.Volume(),2);
               Opens++;
               if(m_position.Select(sym) && m_position.PositionType()==POSITION_TYPE_BUY)
                 {
                  b++;
                  tpb = PositionGetDouble(POSITION_TP);
                  slb = PositionGetDouble(POSITION_SL);
                  tkb = m_position.Ticket();
                  if(op>BuyPriceMax || BuyPriceMax==0)
                    {
                     BuyPriceMax    = op;
                     BuyPriceMaxLot = lt;
                     BuyPriceMaxTic = tkb;
                    }
                  if(op<BuyPriceMin || BuyPriceMin==0)
                    {
                     BuyPriceMin    = op;
                     BuyPriceMinLot = lt;
                     BuyPriceMinTic = tkb;
                    }
                 }
               // ===
               else
                  if(m_position.Select(sym) && m_position.PositionType()==POSITION_TYPE_SELL)
                    {
                     s++;
                     tps = PositionGetDouble(POSITION_TP);
                     sls = PositionGetDouble(POSITION_SL);
                     tks = m_position.Ticket();
                     if(op>SelPriceMax || SelPriceMax==0)
                       {
                        SelPriceMax    = op;
                        SelPriceMaxLot = lt;
                        SelPriceMaxTic = tks;
                       }
                     if(op<SelPriceMin || SelPriceMin==0)
                       {
                        SelPriceMin    = op;
                        SelPriceMinLot = lt;
                        SelPriceMinTic = tks;
                       }
                    }
              }
           }
        }
     }
   double BuyLot=0,SelLot=0;
   if(MartinsMode == Multiply)
     {
      BuyLot = NormalizeDouble(BuyPriceMinLot*LotMultiplier,2);
      SelLot = NormalizeDouble(SelPriceMaxLot*LotMultiplier,2);
     }
   else
      if(MartinsMode == Increment)
        {
         BuyLot = NormalizeDouble(BuyPriceMinLot+LotIncrement,2);
         SelLot = NormalizeDouble(SelPriceMaxLot+LotIncrement,2);
        }
   if(!CheckVolumeValue(sym,iStartLots))
      return;

   double SLsell = 0, SLbuy = 0, TPbuy = 0,TPsell = 0;

   if(StopLoss > 0)
     {
      SLbuy = NormalizeDouble(ask - StopLoss*PipValue*points,digits);
      SLsell = NormalizeDouble(bid + StopLoss*PipValue*points,digits);
     }
   else
     {
      SLbuy = 0;
      SLsell = 0;
     }

   if(TakeProfit > 0)
     {
      TPbuy = NormalizeDouble(ask + TakeProfit*PipValue*points,digits);
      TPsell = NormalizeDouble(bid - TakeProfit*PipValue*points,digits);
     }
   else
     {
      TPbuy = 0;
      TPsell = 0;
     }

   if(((TradeAtNewBar && isNewBar(sym))||(!TradeAtNewBar)) && Times())
     {
      if(!Opens)
        {
         if(b == 0  && (Sig(sym,Period1)=="Buy") && CheckMoneyForTrade(sym,iStartLots,ORDER_TYPE_BUY))
           {
            if(!trade.Buy(NormalizeDouble(iStartLots,2),sym,NormalizeDouble(ask,digits),SLbuy,TPbuy,Commentary))
               Print("Open Trade error #",GetLastError());
            else
               Print("Open Trade Success");
           }
         else
            if(s == 0 && (Sig(sym,Period1)=="Sell") && CheckMoneyForTrade(sym,iStartLots,ORDER_TYPE_SELL))
              {
               if(!trade.Sell(NormalizeDouble(iStartLots,2),sym,NormalizeDouble(bid,digits),SLsell,TPsell,Commentary))
                  Print("Open Trade error #",GetLastError());
               else
                  Print("Open Trade Success");
              }
        }
     }
   if(Opens)
     {
      double Grids = NormalizeDouble(atr(sym,ATRTF,0,1),digits);
      if(AverageMode == AverageDown)
        {
         if(b>0 && CheckMoneyForTrade(sym,BuyLot,ORDER_TYPE_BUY))
           {
            if(b < MaxAverageOrders && BuyPriceMin-ask >= GridMultiplier*Grids)
              {
               if(!trade.Buy(NormalizeDouble(BuyLot,2),sym,NormalizeDouble(ask,digits),slb,tpb,Commentary))
                  Print("Averaging Down error #",GetLastError());
               else
                  Print("Averaging Down Success");
               return;
              }
           }
         else
            if(s>0 && CheckMoneyForTrade(sym,SelLot,ORDER_TYPE_SELL))
              {
               if(s < MaxAverageOrders && bid-SelPriceMax >= GridMultiplier*Grids)
                 {
                  if(!trade.Sell(NormalizeDouble(SelLot,2),sym,NormalizeDouble(bid,digits),sls,tps,Commentary))
                     Print("Averaging Down error #",GetLastError());
                  else
                     Print("Averaging Down Success");
                  return;
                 }
              }
         if(b <= 1)
           {
            Trailing(sym);
           }
         if(b > 1)
           {
            if(ProfitLossOrders(sym) > 1)
               CloseAll(sym);
           }
         if(s <= 1)
           {
            Trailing(sym);
           }
         if(s > 1)
           {
            if(ProfitLossOrders(sym) > 1)
               CloseAll(sym);
           }
        }
      else
         if(AverageMode == AverageUp)
           {
            if(b>0 && CheckMoneyForTrade(sym,BuyLot,ORDER_TYPE_BUY))
              {
               if(b < MaxAverageOrders && ask - GridMultiplier*Grids >= BuyPriceMax)
                 {
                  if(!trade.Buy(NormalizeDouble(BuyLot,2),sym,NormalizeDouble(ask,digits),slb,tpb,Commentary))
                     Print("Averaging Up error #",GetLastError());
                  else
                     Print("Averaging Up Success");
                  return;
                 }
              }
            else
               if(s>0 && CheckMoneyForTrade(sym,SelLot,ORDER_TYPE_SELL))
                 {
                  if(s < MaxAverageOrders && SelPriceMin - GridMultiplier*Grids >= bid)
                    {
                     if(!trade.Sell(NormalizeDouble(SelLot,2),sym,NormalizeDouble(bid,digits),sls,tps,Commentary))
                        Print("Averaging Up error #",GetLastError());
                     else
                        Print("Averaging Up Success");
                     return;
                    }
                 }
            double TrailStart = 0;
            if(b >= MaxAverageOrders)
              {
               TrailStart = BuyPriceMin + TrailingStart*points;
               AverageUpTrail(sym,TrailStart,TrailingStop,TrailingStep);
              }
            if(s >= MaxAverageOrders)
              {
               TrailStart = SelPriceMax - TrailingStart*points;
               AverageUpTrail(sym,TrailStart,TrailingStop,TrailingStep);
              }
           }
         else
            if(AverageMode == None)
              {
               Trailing(sym);
              }
     }

   ResetLastError();
   return;
  }

//************************************************************************************************/
//*                                                                                              */
//************************************************************************************************/
bool CheckVolumeValue(string sym, double volume)
  {
//--- минимально допустимый объем для торговых операций
   double min_volume=SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
      return(false);

//--- максимально допустимый объем для торговых операций
   double max_volume=SymbolInfoDouble(sym,SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
      return(false);

//--- получим минимальную градацию объема
   double volume_step=SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
      return(false);

   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Times()
  {
   MqlDateTime currTime;
   TimeCurrent(currTime);
   int hour0 = currTime.hour;

   if(StartTime < EndTime)
      if(hour0 < StartTime || hour0 >= EndTime)
         return (false);

   if(StartTime > EndTime)
      if(hour0 >= EndTime || hour0 < StartTime)
         return(false);

   return (true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAll(string sym)
  {
   int total=PositionsTotal();
   for(int k=total-1; k>=0; k--)
      if(m_position.SelectByIndex(k))
         if(m_position.Symbol()==sym)
            if(m_position.Magic()==iMagicNumber)
              {
               // position with appropriate ORDER_MAGIC, symbol and order type
               trade.PositionClose(PositionGetInteger(POSITION_TICKET), iSlippage);
               Print("All Positions Closed Successfully");
              }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetProfit(string sym)
  {
   double profit = 0;
   double floating = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      string symbol = PositionGetSymbol(i);
      if(symbol == sym)
        {
         if(PositionGetInteger(POSITION_MAGIC) == iMagicNumber)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY || PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               profit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+AccountInfoDouble(ACCOUNT_COMMISSION_BLOCKED);
               floating = profit;
              }
           }//3
        }//2
     }//1
   return (floating);
  }//0

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)
  {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
//--- call of the checking function
   if(!OrderCalcMargin(type,symb,lots,price,margin))
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewBar(string sym)
  {
   static datetime dtBarCurrent=WRONG_VALUE;
   datetime dtBarPrevious=dtBarCurrent;
   dtBarCurrent=(datetime) SeriesInfoInteger(sym,Period(),SERIES_LASTBAR_DATE);
   bool NewBarFlag=(dtBarCurrent!=dtBarPrevious);
   if(NewBarFlag)
      return(true);
   else
      return (false);

   return (false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RefreshRates(string sym)
  {
   double ask = SymbolInfoDouble(sym,SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym,SYMBOL_BID);
//--- protection against the return value of "zero"
   if(ask==0 || bid==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double tema(string sym, ENUM_TIMEFRAMES tf, int buffer_num, int index)
  {
//--- array for the indicator values
   double arr[];
   double indicator = 0;
   datetime end = iTime(sym,tf,0);
   datetime start = iTime(sym,tf,1);
   ArraySetAsSeries(arr, true);
   int handle = iTEMA(sym,tf,50,0,PRICE_CLOSE);
   int copied = CopyBuffer(handle, buffer_num, 0, bar, arr);
   if(copied>0 && index<copied)
      indicator = arr[index];
   return (indicator);
  }


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double atr(string sym, ENUM_TIMEFRAMES tf, int buffer_num, int index)
  {
//--- array for the indicator values
   double arr[];
   double indicator = 0;
   datetime end = iTime(sym,tf,0);
   datetime start = iTime(sym,tf,1);
   ArraySetAsSeries(arr, true);
   int handle = iATR(sym,ATRTF,ATRPeriod);
   int copied = CopyBuffer(handle, buffer_num, 0, bar, arr);
   if(copied>0 && index<copied)
      indicator = arr[index];
   return (indicator);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Sig(string sym, ENUM_TIMEFRAMES tf)
  {
   string sigs;
   bool sell = false, buy = false, open = false, spikes = false;
   double  close[],supp[],res[],ema[],val[];
   datetime end = iTime(sym,tf,0);
   datetime start = iTime(sym,tf,1);
   ArrayResize(val,bar);
   ArrayResize(supp,bar);
   ArrayResize(res,bar);
   ArrayResize(close,bar);
   ArrayResize(ema,bar);
   ArraySetAsSeries(val,true);
   ArraySetAsSeries(supp,true);
   ArraySetAsSeries(res,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(ema,true);
   for(int x=bar-1; x>=0; x--)
     {
      close[x]=iClose(sym,tf,x);
      ema[x]=tema(sym,tf,0,x);
     }

   if(close[0] > ema[0])
      sigs = "Buy";
   else
      if(close[0] < ema[0])
         sigs = "Sell";
      else
         sigs = "No Signal";

   return(sigs);
  }

//+------------------------------------------------------------------+
void Trailing(string sym)
  {
   int b=0,s=0;
   ulong TicketB=0,TicketS=0;
   double TP = 0,SL = 0, OP = 0;
   double ask = SymbolInfoDouble(sym,SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym,SYMBOL_BID);
   double points = SymbolInfoDouble(sym,SYMBOL_POINT);
   int digits =(int) SymbolInfoInteger(sym,SYMBOL_DIGITS);
   int StopLevel =(int)SymbolInfoInteger(sym,SYMBOL_TRADE_STOPS_LEVEL);

   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==sym)
            if(m_position.Magic()==iMagicNumber)
              {
               if(m_position.Select(sym) && m_position.PositionType()==POSITION_TYPE_BUY)
                 {
                  b++;
                  TicketB=m_position.Ticket();
                  TP = m_position.TakeProfit();
                  SL = m_position.StopLoss();
                  OP = m_position.PriceOpen();
                 }
               if(m_position.Select(sym) && m_position.PositionType()==POSITION_TYPE_SELL)
                 {
                  s++;
                  TicketS=m_position.Ticket();
                  TP = m_position.TakeProfit();
                  SL = m_position.StopLoss();
                  OP = m_position.PriceOpen();
                 }
              }
//---
   if(b > 0)
     {
      if(bid - OP > (TrailingStop+10)*points && (SL < OP || SL == 0))
        {
         if(!trade.PositionModify(TicketB,NormalizeDouble(OP + TrailingStop*points,digits),TP))
            Print("Breakeven error #",GetLastError());
         else
            Print("Breakeven success");
         return;
        }
      if(SL!=0 && SL>OP && bid - SL > (TrailingStep+5)*points)
        {
         if(!trade.PositionModify(TicketB,NormalizeDouble(SL + TrailingStep*points,digits),TP))
            Print("Trailing error #",GetLastError());
         else
            Print("Trailing success");
         return;
        }
     }

   if(s > 0)
     {
      if(OP - ask > (TrailingStop+10)*points && (SL > OP || SL == 0))
        {
         if(!trade.PositionModify(TicketS,NormalizeDouble(OP - TrailingStop*points,digits),TP))
            Print("Breakeven error #",GetLastError());
         else
            Print("Breakeven success");
         return;
        }
      if(SL!=0 && SL<OP && SL - ask > (TrailingStep+5)*points)
        {
         if(!trade.PositionModify(TicketS,NormalizeDouble(SL - TrailingStep*points,digits),TP))
            Print("Trailing error #",GetLastError());
         else
            Print("Trailing success");
         return;
        }
     }

   ResetLastError();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AverageUpTrail(string sym, double openprice, int JumlahPoin,int Step=1)
  {
   int b=0,s=0;
   ulong TicketB=0,TicketS=0;
   double TP = 0,SL = 0, OP = 0;

   double ask = SymbolInfoDouble(sym,SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym,SYMBOL_BID);
   double points = SymbolInfoDouble(sym,SYMBOL_POINT);
   int digits =(int) SymbolInfoInteger(sym,SYMBOL_DIGITS);
   int stopLevel =(int)SymbolInfoInteger(sym,SYMBOL_TRADE_STOPS_LEVEL);

   double TS = JumlahPoin*points;
   double TST = Step*points;
   if(TS < stopLevel*points)
      TS = stopLevel*points;
   else
      TS = TS;
   if(TST < stopLevel*points)
      TST = stopLevel*points;
   else
      TST = TST;
   if(TS < TST)
     {
      Print("Set the Trailing Stop higher than Traling Step");
      return;
     }

   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==sym)
            if(m_position.Magic()==iMagicNumber)
              {
               if(m_position.Select(sym) && m_position.PositionType()==POSITION_TYPE_BUY)
                 {
                  b++;
                  TicketB=m_position.Ticket();
                  TP = m_position.TakeProfit();
                  SL = m_position.StopLoss();
                  OP = m_position.PriceOpen();
                 }
               if(m_position.Select(sym) && m_position.PositionType()==POSITION_TYPE_SELL)
                 {
                  s++;
                  TicketS=m_position.Ticket();
                  TP = m_position.TakeProfit();
                  SL = m_position.StopLoss();
                  OP = m_position.PriceOpen();
                 }
              }

   if(b > 0)
     {
      if((SL == 0 || SL <= openprice) && bid - openprice > TS+TST)
        {
         ModifyAllInstant(sym, openprice + TS);
        }
      else
         if(SL > 0 && SL > openprice && bid - SL > TS+TST+10*points)
           {
            ModifyAllInstant(sym, SL + TS);
           }
     }
   else
      if(s > 0)
        {
         if((SL == 0 || SL >= openprice) && openprice - ask > TS+TST)
           {
            ModifyAllInstant(sym, openprice - TS);
           }
         else
            if(SL > 0 && SL < openprice && SL - ask > TS+TST+10*points)
              {
               ModifyAllInstant(sym, SL - TS);
              }
        }

   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ProfitLossOrders(string sym)
  {
   int count = CountPositions(sym);
   double profit = GetProfit(sym);

   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==sym)
            if(m_position.Magic()==iMagicNumber)
               if(m_position.Type() == POSITION_TYPE_BUY || m_position.Type() == POSITION_TYPE_SELL)
                 {
                  if(count > 1)
                    {
                     if(profit > 0)
                        count++;
                     if(profit < 0)
                        count--;
                    }
                 }
   return (count);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountPositions(string sym)
  {
   int count = 0;
   double profit = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==sym)
            if(m_position.Magic()==iMagicNumber)
               if(m_position.Type() == POSITION_TYPE_BUY || m_position.Type() == POSITION_TYPE_SELL)
                 {
                  count++;
                 }

   return (count);
  }
//+------------------------------------------------------------------+
void ModifyAllInstant(string sym, double sl)
  {
//--- declare and initialize the trade request and result of trade request
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // number of open positions
//--- iterate over all open positions
   for(int i=total-1; i>=0; i--)
     {
      if(PositionGetString(POSITION_SYMBOL) == sym)
        {
         ZeroMemory(request);
         ZeroMemory(result);
         //--- setting the operation parameters
         request.action  =TRADE_ACTION_SLTP; // type of trade operation
         request.position=PositionGetTicket(i);   // ticket of the position
         request.deviation = iSlippage;
         request.symbol  = sym;     // symbol
         request.sl      = sl;                // Stop Loss of the position
         request.tp      = PositionGetDouble(POSITION_TP);                // Take Profit of the position
         //--- output information about the modification
         //--- send the request
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
         //--- information about the operation
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        }
     }
  }
//+------------------------------------------------------------------+
