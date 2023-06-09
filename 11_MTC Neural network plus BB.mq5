//+------------------------------------------------------------------+
//|        MTC Neural network plus MACD(barabashkakvn's edition).mq5 |
//|                             Copyright © 2008, Henadiy E. Batohov |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, Henadiy E. Batohov"
#property version   "1.001"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
input int MaxPosition = 1;
bool MACDsignalrevarse = false;
input bool macdsignalonoff = false; //true:macd_on false:macd_off
input ENUM_TIMEFRAMES MACDtimeperiod = PERIOD_CURRENT;
input ENUM_APPLIED_PRICE MACDpricetype = PRICE_CLOSE;
input bool BBAutoTPSL = 1;
input double bairitu =0.5;
//input int CandleNumbers = 3;
input int      BBPeriod  = 84;
input int      BBShift   = 0;
input double   BBDev     = 1.8;
input ENUM_TIMEFRAMES BBtimeframe = PERIOD_CURRENT;
input int      BBPeriod2  = 84;
input int      BBShift2   = 0;
input double   BBDev2     = 1.8;
input ENUM_TIMEFRAMES BBtimeframe2 = PERIOD_CURRENT;
input ENUM_TIMEFRAMES ADXtimeframe = PERIOD_CURRENT;
input ENUM_TIMEFRAMES ADXtimeframe2 = PERIOD_CURRENT;
input int BBpatern = 1; //BBsig,1-3 100:all
//--- ??????? ????????? ?????????? ADX
input int      ADXPeriod = 40;
input int      ADXLevel  = 45;
input int      ADXPeriod2 = 40;
input int      ADXLevel2  = 45;
input int sltp0= 100;
input int sltp1= 100;
input int sltp2= 100;
input int sltp3= 100;
input int sltp4= 100;
input int sltp5= 100;
input int sltp6= 100;
input int sltp7= 100;
input int sltp8= 100;

//--- input parameters for Neuro part
input int          x11 = 100;
input int          x12 = 100;
input int          x13 = 100;
input int          x14 = 100;
input double       tp1 = 100;
input double       sl1 = 50;
input int          p1=10;
input int          x21 = 100;
input int          x22 = 100;
input int          x23 = 100;
input int          x24 = 100;
input double       tp2 = 100;
input double       sl2 = 50;
input int          p2=10;
input int          x31 = 100;
input int          x32 = 100;
input int          x33 = 100;
input int          x34 = 100;
input int          p3=10;
//--- input parameters
input int          pass=3; //pass0:perceptron_off 1:sell,2:buy,3:final
input double       m_lots = 0.1;
input ulong        m_magic=555;

static datetime    prevtime=0;
static double      take_profit=100;
static double      stop_loss=50;
//---
int    digits_adjust=0;    // tuning for 3 or 5 digits
int    handle_iMACD;       // variable for storing the handle of the iMACD indicator
int BBHandle;                         // ????? ?????????? Bolinger Bands
int BBHandle2;                         // ????? ?????????? Bolinger Bands
int ADXHandle;                        // ????? ?????????? ADX
int ADXHandle2;                        // ????? ?????????? ADX
double BBUp[],BBLow[],MiddleBandArray[];                // ???????????? ??????? ??? ???????? ????????? ???????? Bollinger Bands
double BBUp2[],BBLow2[],MiddleBandArray2[];                // ???????????? ??????? ??? ???????? ????????? ???????? Bollinger Bands
double ADX[];                         // ???????????? ??????? ??? ???????? ????????? ???????? ADX
double ADX2[];                         // ???????????? ??????? ??? ???????? ????????? ???????? ADX
double close[];
double close2[];
bool BBBuy;
bool BBSell;
int MACDsig;
int perceptron;
int CurrentPositontotal;
string CommentOrder;
bool ExistPos,Signal1,Signal2,Signal3,Signal4,Signal5,Signal6,Signal7,Signal8;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//SetMarginMode();
//if(!IsHedging())
//  {
//   Print("Hedging only!");
//   return(INIT_FAILED);
//  }
//---

//--- ???????? ????? ???????????  Bollinger Bands ? ADX
   BBHandle=iBands(Symbol(),BBtimeframe,BBPeriod,BBShift,BBDev,PRICE_CLOSE);
   BBHandle2=iBands(Symbol(),BBtimeframe2,BBPeriod2,BBShift2,BBDev2,PRICE_CLOSE);
   ADXHandle=iADX(Symbol(),ADXtimeframe,ADXPeriod);
   ADXHandle2=iADX(Symbol(),ADXtimeframe2,ADXPeriod2);

   m_symbol.Name(Symbol());                  // sets symbol name
   if(!RefreshRates())
     {
      Print("Error RefreshRates. Bid=",DoubleToString(m_symbol.Bid(),Digits()),
            ", Ask=",DoubleToString(m_symbol.Ask(),Digits()));
      return(INIT_FAILED);
     }
   m_symbol.Refresh();
//--- tuning for 3 or 5 digits
   digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_trade.SetExpertMagicNumber(m_magic);    // sets magic number
//--- create handle of the indicator iMACD;
   handle_iMACD=iMACD(Symbol(),MACDtimeperiod,12,26,9,MACDpricetype);
//--- if the handle is not created
   if(handle_iMACD==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(Symbol(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   if(!RefreshRates2(Symbol()))
     {
      PrevBars=0;
      return;
     }


   if(!IsTradeAllowed())
     {
      again();
      return;
     }
   CurrentPositontotal = OrderTotal();
   if(CurrentPositontotal>=MaxPosition)
     {return;}

   Signlsearch();




   if(MACDsig>0 && BBBuy && perceptron>0 && macdsignalonoff==true)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Buy(m_lots,Symbol(),m_symbol.Ask(),
                      m_symbol.Ask()-stop_loss*Point()*digits_adjust,
                      m_symbol.Ask()+take_profit*Point()*digits_adjust,CommentOrder))
        {
         again();
        }
       Print(CommentOrder);
      CommentOrder="";
     }
   if(BBBuy && perceptron>0 && macdsignalonoff==false)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Buy(m_lots,Symbol(),m_symbol.Ask(),
                      m_symbol.Ask()-stop_loss*Point()*digits_adjust,
                      m_symbol.Ask()+take_profit*Point()*digits_adjust,CommentOrder))
        {
         again();
        }
        Print(CommentOrder);
      CommentOrder="";
     }
   if(MACDsig>0 && BBBuy &&  macdsignalonoff==true && pass==0)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Buy(m_lots,Symbol(),m_symbol.Ask(),
                      m_symbol.Ask()-stop_loss*Point()*digits_adjust,
                      m_symbol.Ask()+take_profit*Point()*digits_adjust,CommentOrder))
        {
         again();
        }
        Print(CommentOrder);
      CommentOrder="";
     }
   if(BBBuy &&  macdsignalonoff==false && pass==0)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Buy(m_lots,Symbol(),m_symbol.Ask(),
                      m_symbol.Ask()-stop_loss*Point()*digits_adjust,
                      m_symbol.Ask()+take_profit*Point()*digits_adjust,CommentOrder))
        {
         again();
        }
        Print(CommentOrder);
      CommentOrder="";
     }

   if(MACDsig<0 && BBSell && perceptron<0 && macdsignalonoff==true)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Sell(m_lots,Symbol(),m_symbol.Bid(),
                       m_symbol.Bid()+stop_loss*Point()*digits_adjust,
                       m_symbol.Bid()-take_profit*Point()*digits_adjust,CommentOrder))
        {
         again();
        }
        Print(CommentOrder);
      CommentOrder="";
     }
   if(BBSell && perceptron<0 && macdsignalonoff==false)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Sell(m_lots,Symbol(),m_symbol.Bid(),
                       m_symbol.Bid()+stop_loss*Point()*digits_adjust,
                       m_symbol.Bid()-take_profit*Point()*digits_adjust,CommentOrder))
        {
         again();
        }
        Print(CommentOrder);
      CommentOrder="";
     }
   if(MACDsig<0 && BBSell && macdsignalonoff==true && pass==0)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Sell(m_lots,Symbol(),m_symbol.Bid(),
                       m_symbol.Bid()+stop_loss*Point()*digits_adjust,
                       m_symbol.Bid()-take_profit*Point()*digits_adjust,CommentOrder))
        {
         again();
        }
        Print(CommentOrder);
      CommentOrder="";
     }
   if(BBSell && macdsignalonoff==false && pass==0)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Sell(m_lots,Symbol(),m_symbol.Bid(),
                       m_symbol.Bid()+stop_loss*Point()*digits_adjust,
                       m_symbol.Bid()-take_profit*Point()*digits_adjust,CommentOrder))
        {
         again();
        }
        Print(CommentOrder);
      CommentOrder="";
     }

   return;
  }
//+------------------------------------------------------------------+
//| calculate perciptrons value                                      |
//+------------------------------------------------------------------+
int Supervisor()
  {
   if(pass>=3)
     {
      if(perceptron3()>0)
        {
         if(perceptron2()>0)
           {
            stop_loss=sl2;
            take_profit=tp2;
            return(1);
           }
        }
      else
        {
         if(perceptron1()<0)
           {
            stop_loss=sl1;
            take_profit=tp1;
            return(-1);
           }
        }
      return(0);
     }

   if(pass==2)
     {
      if(perceptron2()>0)
        {
         stop_loss=sl2;
         take_profit=tp2;
         return(1);
        }
      else
        {
         return(0);
        }
     }

   if(pass==1)
     {
      if(perceptron1()<0)
        {
         stop_loss=sl1;
         take_profit=tp1;
         return(-1);
        }
      else
        {
         return(0);
        }
     }
   stop_loss=sl0;
   take_profit=tp0;
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double perceptron1()
  {
   double       w1 = x11 - 100;
   double       w2 = x12 - 100;
   double       w3 = x13 - 100;
   double       w4 = x14 - 100;
   double a1 = iClose(m_symbol.Name(),Period(),0) - iOpen(m_symbol.Name(),Period(),p1);
   double a2 = iOpen(m_symbol.Name(),Period(),p1) - iOpen(m_symbol.Name(),Period(),p1 * 2);
   double a3 = iOpen(m_symbol.Name(),Period(),p1 * 2) - iOpen(m_symbol.Name(),Period(),p1 * 3);
   double a4 = iOpen(m_symbol.Name(),Period(),p1 * 3) - iOpen(m_symbol.Name(),Period(),p1 * 4);
   return(w1 * a1 + w2 * a2 + w3 * a3 + w4 * a4);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double perceptron2()
  {
   double       w1 = x21 - 100;
   double       w2 = x22 - 100;
   double       w3 = x23 - 100;
   double       w4 = x24 - 100;
   double a1 = iClose(m_symbol.Name(),Period(),0) - iOpen(m_symbol.Name(),Period(),p2);
   double a2 = iOpen(m_symbol.Name(),Period(),p2) - iOpen(m_symbol.Name(),Period(),p2 * 2);
   double a3 = iOpen(m_symbol.Name(),Period(),p2 * 2) - iOpen(m_symbol.Name(),Period(),p2 * 3);
   double a4 = iOpen(m_symbol.Name(),Period(),p2 * 3) - iOpen(m_symbol.Name(),Period(),p2 * 4);
   return(w1 * a1 + w2 * a2 + w3 * a3 + w4 * a4);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double perceptron3()
  {
   double       w1 = x31 - 100;
   double       w2 = x32 - 100;
   double       w3 = x33 - 100;
   double       w4 = x34 - 100;
   double a1 = iClose(m_symbol.Name(),Period(),0) - iOpen(m_symbol.Name(),Period(),p3);
   double a2 = iOpen(m_symbol.Name(),Period(),p3) - iOpen(m_symbol.Name(),Period(),p3 * 2);
   double a3 = iOpen(m_symbol.Name(),Period(),p3 * 2) - iOpen(m_symbol.Name(),Period(),p3 * 3);
   double a4 = iOpen(m_symbol.Name(),Period(),p3 * 3) - iOpen(m_symbol.Name(),Period(),p3 * 4);
   return(w1 * a1 + w2 * a2 + w3 * a3 + w4 * a4);
  }
//+------------------------------------------------------------------+
//| Calculate MACD value                                             |
//+------------------------------------------------------------------+
int getMACD()
  {
   double MacdCurrent,MacdPrevious,SignalCurrent,SignalPrevious;

   MacdCurrent=iMACDGet(MAIN_LINE,0);
   MacdPrevious=iMACDGet(MAIN_LINE,2);
   SignalCurrent=iMACDGet(SIGNAL_LINE,0);
   SignalPrevious=iMACDGet(SIGNAL_LINE,2);

   if(MacdCurrent<0 && MacdCurrent>=SignalCurrent && MacdPrevious<=SignalPrevious)
     {
      if(MACDsignalrevarse==false)
        {
         return(1);
        }
      else
         return(-1);

     }


   if(MacdCurrent>0 && MacdCurrent<=SignalCurrent && MacdPrevious>=SignalPrevious)
     {
      if(MACDsignalrevarse==false)
        {
         return(-1);
        }
      else
         return(1);

     }


   return(0);
  }
//+------------------------------------------------------------------+
//| pause and try to do expert again                                 |
//+------------------------------------------------------------------+
void again()
  {
   prevtime=0;
   Sleep(30000);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMACD                               |
//|  the buffer numbers are the following:                           |
//|   0 - MAIN_LINE, 1 - SIGNAL_LINE                                 |
//+------------------------------------------------------------------+
double iMACDGet(const int buffer,const int index)
  {
   double MACD[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iMACDBuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iMACD,buffer,index,1,MACD)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(MACD[0]);
  }
//+------------------------------------------------------------------+
//| Gets the information about permission to trade                   |
//+------------------------------------------------------------------+
bool IsTradeAllowed()
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      Alert("Check if automated trading is allowed in the terminal settings!");
      return(false);
     }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      Alert("Check if automated trading is allowed in the terminal settings!");
      return(false);
     }
   else
     {
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         Alert("Automated trading is forbidden in the program settings for ",__FILE__);
         return(false);
        }
     }
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
     {
      Alert("Automated trading is forbidden for the account ",AccountInfoInteger(ACCOUNT_LOGIN),
            " at the trade server side");
      return(false);
     }
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
     {
      Comment("Trading is forbidden for the account ",AccountInfoInteger(ACCOUNT_LOGIN),
              ".\n Perhaps an investor password has been used to connect to the trading account.",
              "\n Check the terminal journal for the following entry:",
              "\n\'",AccountInfoInteger(ACCOUNT_LOGIN),"\': trading has been disabled - investor mode.");
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RefreshRates2(string sym)
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
//-----------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   double  param = 0.0;
   double  balance = TesterStatistics(STAT_PROFIT);
   if(balance<=0)
     {
      param=0;
      return(param);

     }


   double sharpratio = TesterStatistics(STAT_SHARPE_RATIO);
   if(sharpratio<1)
     {
      param=0;
      return(param);

     }

   double profitfactor = TesterStatistics(STAT_PROFIT_FACTOR);

   if(profitfactor<1)
     {
      param=0;
      return(param);

     }
   double  min_dd = TesterStatistics(STAT_BALANCE_DD);
   if(min_dd > 0.0)
     {
      min_dd = 1.0 / min_dd;
     }
   double  trades_number = TesterStatistics(STAT_TRADES);
   if(trades_number<=100)
     {
      param=0;
      return(param);

     }

   param = (balance * trades_number *min_dd*sharpratio*profitfactor)/10000 ;
   return(param);
  }
//+------------------------------------------------------------------+
void Signlsearch()
  {

   MACDsig       = getMACD();
   perceptron = Supervisor();

   double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);

   ArraySetAsSeries(BBUp,true);
   ArraySetAsSeries(BBLow,true);
   ArraySetAsSeries(ADX,true);
   ArraySetAsSeries(MiddleBandArray,true);
   ArraySetAsSeries(close,true);
//--- ???????? ???????? ?????????? Bolinger Bands ????????? ??????
   if(CopyBuffer(BBHandle,1,0,3,BBUp)<0 || CopyBuffer(BBHandle,2,0,3,BBLow)<0)
     {
      Alert("?????? ??????????? ??????? ?????????? Bollinger Bands - ????? ??????:",GetLastError(),"!");
      return;
     }
//--- ???????? ???????? ?????????? ADX ????????? ??????
   if(CopyBuffer(ADXHandle,0,0,3,ADX)<0)
     {
      Alert("?????? ??????????? ??????? ?????????? ADX - ????? ??????:",GetLastError(),"!");
      return;
     }
   CopyBuffer(BBHandle,0,0,3,MiddleBandArray);
   CopyClose(Symbol(),BBtimeframe,0,3,close);

   ArraySetAsSeries(BBUp2,true);
   ArraySetAsSeries(BBLow2,true);
   ArraySetAsSeries(ADX2,true);
   ArraySetAsSeries(MiddleBandArray2,true);
   ArraySetAsSeries(close2,true);
//--- ???????? ???????? ?????????? Bolinger Bands ????????? ??????
   if(CopyBuffer(BBHandle2,1,0,3,BBUp2)<0 || CopyBuffer(BBHandle2,2,0,3,BBLow2)<0)
     {
      Alert("?????? ??????????? ??????? ?????????? Bollinger Bands - ????? ??????:",GetLastError(),"!");
      return;
     }
//--- ???????? ???????? ?????????? ADX ????????? ??????
   if(CopyBuffer(ADXHandle2,0,0,3,ADX2)<0)
     {
      Alert("?????? ??????????? ??????? ?????????? ADX - ????? ??????:",GetLastError(),"!");
      return;
     }
   CopyBuffer(BBHandle2,0,0,3,MiddleBandArray2);
   CopyClose(Symbol(),BBtimeframe2,0,3,close2);


   BBBuy = false;
   BBSell = false;


   if(BBpatern==1||BBpatern==100)
     {
      if(ask<=BBLow[1] && ADX[1]<=ADXLevel)
        {
         PosSignalCheck("Signal1");
         if(ExistPos==false)
           {
            BBBuy = true;
            stop_loss=sltp1;
            take_profit=sltp1;
            CommentOrder = "Signal1";
            Signal1=true;
            if(BBAutoTPSL)
              {
               take_profit=((MiddleBandArray[0]-ask)/Point())*bairitu;
               stop_loss=take_profit;
              }

           }
        }
      if(bid>=BBUp[1] && ADX[1]<=ADXLevel)
        {
         PosSignalCheck("Signal2");
         if(ExistPos==false)
           {
            BBSell = true;
            stop_loss=sltp2;
            take_profit=sltp2;
            CommentOrder = "Signal2";
            Signal2=true;
            if(BBAutoTPSL)
              {
               take_profit=((bid-MiddleBandArray[0])/Point())*bairitu;
               stop_loss=take_profit;
              }
           }


        }
     }
   if(BBpatern==2||BBpatern==100)
     {
      if(ask>=BBUp2[1] && ADX2[1]>=ADXLevel)
        {
         PosSignalCheck("Signal3");
         if(ExistPos==false)
           {
            BBBuy = true;
            
            stop_loss=sltp3;
            take_profit=sltp3;
            CommentOrder = "Signal3";
            Signal3=true;
            if(BBAutoTPSL)
              {
               stop_loss=((ask-MiddleBandArray2[0])/Point())*bairitu;
               take_profit=stop_loss;
              }
           }

        }
      if(bid<=BBLow2[1] && ADX2[1]>=ADXLevel)
        {
         PosSignalCheck("Signal4");
         if(ExistPos==false)
           {
            BBSell = true;
            
            stop_loss=sltp4;
            take_profit=sltp4;
            CommentOrder = "Signal4";
            Signal4=true;
            if(BBAutoTPSL)
              {
               stop_loss=((MiddleBandArray2[0]-bid)/Point())*bairitu;
               take_profit=stop_loss;
              }
           }

        }
     }

   if(BBpatern==3||BBpatern==100)
     {
      double            DiffOpenLower = (close[2]-BBLow[2]);
      double            DiffCloseLower = (close[1]-BBLow[1]);
      double            DiffOpenUpper = (close[2]-BBUp[2]);
      double            DiffCloseUpper = (close[1]-BBUp[1]);
      double            DiffOpenLower2 = (close2[2]-BBLow2[2]);
      double            DiffCloseLower2 = (close2[1]-BBLow2[1]);
      double            DiffOpenUpper2 = (close2[2]-BBUp2[2]);
      double            DiffCloseUpper2 = (close2[1]-BBUp2[1]);


      if(ADX[1]<=ADXLevel)
        {
         //--- if the model 0 is used and the open price is below the lower indicator and close price is above the lower indicator
         if(DiffOpenLower<0.0 && DiffCloseLower>0.0)
           {
            PosSignalCheck("Signal5");
            if(ExistPos==false)
              {
               BBBuy = true;
               
            stop_loss=sltp5;
            take_profit=sltp5;
               CommentOrder = "Signal5";
               Signal5=true;
               if(BBAutoTPSL)
                 {
                  take_profit=((MiddleBandArray[0]-ask)/Point())*bairitu;
                  stop_loss=take_profit;
                 }
              }



           }
         //--- if the model 0 is used and the open price is above the upper indicator and close price is below the upper indicator
         if(DiffOpenUpper>0.0 && DiffCloseUpper<0.0)
           {
            PosSignalCheck("Signal6");
            if(ExistPos==false)
              {
               BBSell = true;
            stop_loss=sltp6;
            take_profit=sltp6;
               CommentOrder = "Signal6";
               Signal6=true;
               if(BBAutoTPSL)
                 {
                  take_profit=((bid-MiddleBandArray[0])/Point())*bairitu;
                  stop_loss=take_profit;
                 }
              }



           }

        }

      if(ADX2[1]>=ADXLevel)
        {
         //--- if the model 1 is used and the open price is below the upper indicator and close price is above the upper indicator
         if(DiffOpenUpper2<0.0 && DiffCloseUpper2>0.0)
           {
            PosSignalCheck("Signal7");
            if(ExistPos==false)
              {
               BBBuy = true;
            stop_loss=sltp7;
            take_profit=sltp7;
               CommentOrder = "Signal7";
               Signal7=true;
               if(BBAutoTPSL)
                 {
                  stop_loss=((ask-MiddleBandArray2[0])/Point())*bairitu;
                  take_profit=stop_loss;
                 }
              }


           }
         //--- if the model 1 is used and the open price is above the lower indicator and close price is below the lower indicator
         if(DiffOpenLower2>0.0 && DiffCloseLower2<0.0)
           {
            PosSignalCheck("Signal8");
            if(ExistPos==false)
              {
               BBSell = true;
            stop_loss=sltp8;
            take_profit=sltp8;
               CommentOrder = "Signal8";
               Signal8=true;
               if(BBAutoTPSL)
                 {
                  stop_loss=((MiddleBandArray2[0]-bid)/Point())*bairitu;
                  take_profit=stop_loss;
                 }
              }


           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int OrderTotal()
  {

   int count = 0;

   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of open positions
     {
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==Symbol() && m_position.Magic()==m_magic)
            count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PosSignalCheck(string checkedSignal)
  {

   ExistPos = false;
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of open positions
     {
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==Symbol() && m_position.Magic()==m_magic)
            if(m_position.Comment()==checkedSignal)
               ExistPos=true;
     }
  }
//+------------------------------------------------------------------+
