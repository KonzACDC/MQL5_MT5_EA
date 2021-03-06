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
//--- input parameters for Neuro part
input ENUM_TIMEFRAMES MACDperiod = PERIOD_CURRENT ;
input int          x11 = 100; //X11 = 0-200
input int          x12 = 100;
input int          x13 = 100;
input int          x14 = 100;
input double       tp1 = 100;
input double       sl1 = 50;
input int          p1=10;//p1:shift 3-100
input int          x21 = 100;
input int          x22 = 100;
input int          x23 = 100;
input int          x24 = 100;
input double       tp2 = 100;
input double       sl2 = 50;
input int          p2=10;//p2:shift 3-100
input int          x31 = 100;
input int          x32 = 100;
input int          x33 = 100;
input int          x34 = 100;
input int          p3=10;//p3:shift 3-100
//--- input parameters
input int          pass=3; //Pass:pass0BAsic,pass1sell,pass2buy,pass3上層&result
input double       m_lots = 0.1;
input ulong        m_magic=555;
input double       tpbasic = 100;
input double       slbasic = 50;


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
input ENUM_TIMEFRAMES RSIperiod = PERIOD_CURRENT ;

//---
//input ulong    m_magic=345727040;// magic number
//---
//ulong  m_slippage=10;               // slippage
//double ExtSLTP=0.0;
int    handle_iRSI;                 // variable for storing the handle of the iRSI indicator
string RNNSignal;
//double m_adjusted_point;            // point value adjusted for 3 or 5 points
//RNN


static datetime    prevtime=0;
static double      take_profit=100;
static double      stop_loss=50;
//---
int    digits_adjust=0;    // tuning for 3 or 5 digits
int    handle_iMACD;       // variable for storing the handle of the iMACD indicator 
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
   handle_iMACD=iMACD(Symbol(),MACDperiod,12,26,9,PRICE_CLOSE);
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
     
          //RNN
     //---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);

//--- create handle of the indicator iRSI
   handle_iRSI=iRSI(m_symbol.Name(),RSIperiod,Inp_RSI_ma_period,Inp_RSI_applied_price);
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

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(iTime(m_symbol.Name(),Period(),0)==prevtime)
      return;
   prevtime=iTime(m_symbol.Name(),Period(),0);

   if(!IsTradeAllowed())
     {
      again();
      return;
     }



   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==Symbol() && m_position.Magic()==m_magic)
            return;
stop_loss = tpbasic;
take_profit = slbasic;

   int MACD       = getMACD();
   int perceptron = Supervisor();

   if(perceptron>0 && pass == 0)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Buy(m_lots,Symbol(),m_symbol.Ask(),
         m_symbol.Ask()-stop_loss*Point()*digits_adjust,
         m_symbol.Ask()+take_profit*Point()*digits_adjust,MQLInfoString(MQL_PROGRAM_NAME)))
        {
         again();
        }
     }
   if(perceptron<0 && pass == 0)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Sell(m_lots,Symbol(),m_symbol.Bid(),
         m_symbol.Bid()+stop_loss*Point()*digits_adjust,
         m_symbol.Bid()-take_profit*Point()*digits_adjust,MQLInfoString(MQL_PROGRAM_NAME)))
        {
         again();
        }
     }



   if(MACD>0 && perceptron>0 && pass != 0)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Buy(m_lots,Symbol(),m_symbol.Ask(),
         m_symbol.Ask()-stop_loss*Point()*digits_adjust,
         m_symbol.Ask()+take_profit*Point()*digits_adjust,MQLInfoString(MQL_PROGRAM_NAME)))
        {
         again();
        }
     }

   if(MACD<0 && perceptron<0 && pass != 0)
     {
      if(!RefreshRates())
         return;

      if(!m_trade.Sell(m_lots,Symbol(),m_symbol.Bid(),
         m_symbol.Bid()+stop_loss*Point()*digits_adjust,
         m_symbol.Bid()-take_profit*Point()*digits_adjust,MQLInfoString(MQL_PROGRAM_NAME)))
        {
         again();
        }
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
      return(basicTradingSystem());
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
         return(basicTradingSystem());
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
         return(basicTradingSystem());
        }
     }

   return(basicTradingSystem());
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
      return(1);

   if(MacdCurrent>0 && MacdCurrent<=SignalCurrent && MacdPrevious>=SignalPrevious)
      return(-1);

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
double GetProbability(double gp1,double gp2,double gp3)
  {
   double y0 = x0;
   double y1 = x1;
   double y2 = x2;
   double y3 = x3;
   double y4 = x4;
   double y5 = x5;
   double y6 = x6;
   double y7 = x7;

   double pn1 = 1.0 - gp1;
   double pn2 = 1.0 - gp2;
   double pn3 = 1.0 - gp3;
//--- calculation of probability in percent
   double probability=
                      pn1 *(pn2 *(pn3*y0+
                      gp3*y1)+
                      gp2 *(pn3*y2+
                      gp3*y3))+
                      gp1 *(pn2 *(pn3*y4+
                      gp3*y5)+
                      gp2 *(pn3*y6+
                      gp3*y7));
                      //--- percent into probabilities
                      probability=probability/100.0;
//---
   return (probability);
  }

double basicTradingSystem()
{
//RNN
     
     //--- calculate the trading signal
   double sp=TradesSingal();

   double stoploss=0.0;
   double takeprofit=0.0;

   string s="";
   int ticket=-1;

   if(sp<0.0)
     {
      return(1);
     }
   else
     {
     return(-1);
     }
//RNN



}

//RNN