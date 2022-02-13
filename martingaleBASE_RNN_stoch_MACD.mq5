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
//RNN
#include <Trade\SymbolInfo.mqh>  
CSymbolInfo    m_symbol;                     // symbol info object
//RNN

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
input    int                     TEMAperiod      = 50; //TEMA period
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

//RNN
//--- input parameters
//input double      InpLots  = 1.0;   // Lots
//input ushort      InpSLTP  = 100;   // Stop Loss and TakeProfit (in pips)
input int         x0       = 6;     // x0: Setting from 0 to 100 in increments of 1
input int         x1       = 96;    // x1: Setting from 0 to 100 in increments of 1
input int         x2       = 90;    // x2: Setting from 0 to 100 in increments of 1
input int         x3       = 35;    // x3: Setting from 0 to 100 in increments of 1
input int         x4       = 64;    // x4: Setting from 0 to 100 in increments of 1
input int         x5       = 83;    // x5: Setting from 0 to 100 in increments of 1
input int         x6       = 66;    // x6: Setting from 0 to 100 in increments of 1 
input int         x7       = 50;    // x7: Setting from 0 to 100 in increments of 1
//---
input int                  Inp_RSI_ma_period    = 9;           // RSI: averaging period 
input ENUM_APPLIED_PRICE   Inp_RSI_applied_price= PRICE_OPEN;  // RSI: type of price
//---
//input ulong    m_magic=345727040;// magic number
//---
//ulong  m_slippage=10;               // slippage
//double ExtSLTP=0.0;
int    handle_iRSI;                 // variable for storing the handle of the iRSI indicator
string RNNSignal;
//double m_adjusted_point;            // point value adjusted for 3 or 5 points
//RNN
//SM
input    ENUM_TIMEFRAMES         MACDTF           = PERIOD_CURRENT;  //MACD Timeframe
input    ENUM_TIMEFRAMES         STOTF           = PERIOD_CURRENT;  //STO Timeframe
input    ENUM_TIMEFRAMES         MACDTF2           = PERIOD_CURRENT;  //MACD2 Timeframe
input    ENUM_TIMEFRAMES         STOTF2           = PERIOD_CURRENT;  //STO2 Timeframe
string StochMACDsignal;
//SM
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
   TEMA = iTEMA(Symbol(),Period(),TEMAperiod,0,PRICE_OPEN);
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
     //RNN
     //---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);

//--- create handle of the indicator iRSI
   handle_iRSI=iRSI(m_symbol.Name(),Period(),Inp_RSI_ma_period,Inp_RSI_applied_price);
//--- if the handle is not created 
   if(handle_iRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//RNN
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
//RNN
  //--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   if(!RefreshRates())
     {
      PrevBars=0;
      return;
     }
     
   double macdArray[];
   double KArray[];
   double DArray[];
   
   double macdArray2[];
   double KArray2[];
   double DArray2[];

   
   ArraySetAsSeries(macdArray, true);
   ArraySetAsSeries(KArray, true);
   ArraySetAsSeries(DArray, true);
   
      ArraySetAsSeries(macdArray2, true);
   ArraySetAsSeries(KArray2, true);
   ArraySetAsSeries(DArray2, true);

   
   int MACD = iMACD(_Symbol, MACDTF, 12, 26, 9, PRICE_OPEN);
   int StochasticDef = iStochastic(_Symbol, STOTF, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   int MACD2 = iMACD(_Symbol, MACDTF2, 12, 26, 9, PRICE_OPEN);
   int StochasticDef2 = iStochastic(_Symbol, STOTF2, 5, 3, 3, MODE_SMA, STO_LOWHIGH);

   
   CopyBuffer(MACD, 0, 0, 3, macdArray);
   CopyBuffer(MACD2, 0, 0, 3, macdArray2);

   
   CopyBuffer(StochasticDef, 0, 0, 3, KArray);
   CopyBuffer(StochasticDef, 1, 0, 3, DArray);
   CopyBuffer(StochasticDef2, 0, 0, 3, KArray2);
   CopyBuffer(StochasticDef2, 1, 0, 3, DArray2);

   
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   
   if( KArray[0] < 20 && DArray[0] < 20 && macdArray[0] > 0 && KArray2[0] < 20 && macdArray2[0] > 0)
   {
      StochMACDsignal = "Buy";
   }
   
   if( KArray[0] > 80 && DArray[0] > 80 && macdArray[0] < 0 && KArray2[0] > 80 && macdArray2[0] < 0)
   {
      StochMACDsignal = "Sell";
   }
     
     
     //--- calculate the trading signal
   double sp=TradesSingal();

   double stoploss=0.0;
   double takeprofit=0.0;

   string s="";
   int ticket=-1;

   if(sp<0.0)
     {
      RNNSignal = "Buy";
     }
   else
     {
     RNNSignal = "Sell";
     }
//RNN

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
//         if(b == 0  && (Sig(sym,Period1)=="Buy") && RNNSignal == "Buy" && CheckMoneyForTrade(sym,iStartLots,ORDER_TYPE_BUY))
//         if(b == 0  && RNNSignal == "Buy" && CheckMoneyForTrade(sym,iStartLots,ORDER_TYPE_BUY))
         if(b == 0  && StochMACDsignal == "Buy" && RNNSignal == "Buy" && CheckMoneyForTrade(sym,iStartLots,ORDER_TYPE_BUY))
 //        if(b == 0 && (Sig(sym,Period1)=="Buy")  && StochMACDsignal == "Buy" && RNNSignal == "Buy" && CheckMoneyForTrade(sym,iStartLots,ORDER_TYPE_BUY))
         {
            if(!trade.Buy(NormalizeDouble(iStartLots,2),sym,NormalizeDouble(ask,digits),SLbuy,TPbuy,Commentary))
               Print("Open Trade error #",GetLastError());
            else
               Print("Open Trade Success");
           }
         else
//            if(s == 0 && (Sig(sym,Period1)=="Sell") && RNNSignal == "Sell" && CheckMoneyForTrade(sym,iStartLots,ORDER_TYPE_SELL))
//             if(s == 0 && RNNSignal == "Sell" && CheckMoneyForTrade(sym,iStartLots,ORDER_TYPE_SELL))
            if(s == 0 && StochMACDsignal == "Sell" && RNNSignal == "Sell" && CheckMoneyForTrade(sym,iStartLots,ORDER_TYPE_SELL))
//            if(s == 0 && (Sig(sym,Period1)=="Sell")  && StochMACDsignal == "Sell" && RNNSignal == "Sell" && CheckMoneyForTrade(sym,iStartLots,ORDER_TYPE_SELL))
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
//RNN
//+------------------------------------------------------------------+
//| Converts probability into a trading signal                       |
//+------------------------------------------------------------------+
double TradesSingal()
  {
//--- read indicator volume
   double a1=0.0,a2=0.0,a3=0.0;
   GetRSI(a1,a2,a3);
//--- calculate the probability of a trading signal for a short position.
   double result=GetProbability(a1,a2,a3);

   string s=m_symbol.Name()+", Probability for Short (Sell) position: "+DoubleToString(result,4);

   if(result>0.5)
     {
      Print(s);
     }
   else
     {
      double r=1.0-result;
      Print(s);
      s=m_symbol.Name()+", Probability for Long (Buy) position: "+DoubleToString(r,4);
     }

   SendMail(s,s);
//-- linear sigmoid translates values from 0 to 1 into values from -1 to +1
   result=result*2.0-1.0;
   Print("Result = ",result);
//---
   return(result);
  }
  
  //+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetRSI(double &a1,double &a2,double &a3)
  {
   a1=0.0;
   a2=0.0;
   a3=0.0;

   double rsi_array[];
   ArraySetAsSeries(rsi_array,true);
   int buffer=0,start_pos=0,count=Inp_RSI_ma_period*2+1;

   if(!iGetArray(handle_iRSI,buffer,start_pos,count,rsi_array))
      return;

   a1=rsi_array[0]/100.0;
   a2=rsi_array[Inp_RSI_ma_period]/100.0;
   a3=rsi_array[Inp_RSI_ma_period*2]/100.0;
//---
  }
//+------------------------------------------------------------------+
//| Get value of buffers                                             |
//+------------------------------------------------------------------+
double iGetArray(const int handle,const int buffer,const int start_pos,const int count,double &arr_buffer[])
  {
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iBands array with values from the indicator buffer
   int copied=CopyBuffer(handle,buffer,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
   return(result);
  }
//+------------------------------------------------------------------+
//| Calculation of the probability of a trading signal               | 
//|  for a short position                                            |
//| p1, p2, p3 - signals of TA indicators or oscillators             |
//|  in the range from 0 to 1                                        |
//+------------------------------------------------------------------+
double GetProbability(double p1,double p2,double p3)
  {
   double y0 = x0;
   double y1 = x1;
   double y2 = x2;
   double y3 = x3;
   double y4 = x4;
   double y5 = x5;
   double y6 = x6;
   double y7 = x7;

   double pn1 = 1.0 - p1;
   double pn2 = 1.0 - p2;
   double pn3 = 1.0 - p3;
//--- calculation of probability in percent
   double probability=
                      pn1 *(pn2 *(pn3*y0+
                      p3*y1)+
                      p2 *(pn3*y2+
                      p3*y3))+
                      p1 *(pn2 *(pn3*y4+
                      p3*y5)+
                      p2 *(pn3*y6+
                      p3*y7));
                      //--- percent into probabilities
                      probability=probability/100.0;
//---
   return (probability);
  }
  //+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }

//RNN