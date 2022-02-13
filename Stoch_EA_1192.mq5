
// More information about this indicator can be found at:
//http://fxcodebase.com/code/viewtopic.php?f=38&t=69785

//+------------------------------------------------------------------+
//|                               Copyright © 2019, Gehtsoft USA LLC | 
//|                                            http://fxcodebase.com |
//+------------------------------------------------------------------+
//|                                      Developed by : Mario Jemic  |
//|                                          mario.jemic@gmail.com   |
//+------------------------------------------------------------------+
//|                                 Support our efforts by donating  |
//|                                  Paypal : https://goo.gl/9Rj74e  |
//+------------------------------------------------------------------+
//|                                Patreon :  https://goo.gl/GdXWeN  |
//|                    BitCoin : 15VCJTLaz12Amr7adHSBtL9v8XomURo9RF  |
//|               BitCoin Cash : 1BEtS465S3Su438Kc58h2sqvVvHK9Mijtg  |
//|           Ethereum : 0x8C110cD61538fb6d7A2B47858F0c0AaBd663068D  |
//|                   LiteCoin : LLU8PSY2vsq7B9kRELLZQcKf5nJQrdeqwD  |
//+------------------------------------------------------------------+


#property copyright "Nicholas"
#property link      ""
#property version   "1.00"

#include<Trade/Trade.mqh>
#include <Trade\SymbolInfo.mqh>  

CTrade trade;
CSymbolInfo    m_symbol;                     // symbol info object

input double lotSize = 0.05;

input int staticSL = 100;
input int staticTP = 150;

int maxPositions = 1;

int OnInit()
  {
   trade.SetExpertMagicNumber(001192);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  //--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   if(!RefreshRates())
     {
      PrevBars=iTime(1);
      return;
     }

   double macdArray[];
   double KArray[];
   double DArray[];
   
   ArraySetAsSeries(macdArray, true);
   ArraySetAsSeries(KArray, true);
   ArraySetAsSeries(DArray, true);
   
   int MACD = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
   int StochasticDef = iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   
   CopyBuffer(MACD, 0, 0, 3, macdArray);
   
   CopyBuffer(StochasticDef, 0, 0, 3, KArray);
   CopyBuffer(StochasticDef, 1, 0, 3, DArray);
   
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   
   if(maxPositions != PositionsTotal() && KArray[0] < 20 && macdArray[0] > 0)
   {
      trade.Buy(lotSize, _Symbol, Ask, Ask - staticSL * _Point, Ask + staticTP * _Point);
   }
   
   if(maxPositions != PositionsTotal() && KArray[0] > 80 && macdArray[0] < 0)
   {
      trade.Sell(lotSize, _Symbol, Bid, Bid + staticSL * _Point, Bid - staticTP * _Point);
   }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+ 
//| Get Time for specified bar index                                 | 
//+------------------------------------------------------------------+ 
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0;
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
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
