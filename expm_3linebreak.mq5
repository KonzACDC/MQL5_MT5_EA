//+------------------------------------------------------------------+
//|                                              ExpM_3LineBreak.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\3LineBreakSignal.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string          Expert_Title         ="ExpM_3LineBreak"; // Document name
ulong                 Expert_MagicNumber   =6164;              // 
bool                  Expert_EveryTick     =false;             // 
//--- inputs for main signal
input int             Signal_ThresholdOpen =40;                // Signal threshold value to open [0...100]
input int             Signal_ThresholdClose=20;                // Signal threshold value to close [0...100]
input double          Signal_PriceLevel    =0.0;               // Price level to execute a deal
input double          Signal_StopLevel     =50.0;              // Stop Loss level (in points)
input double          Signal_TakeLevel     =50.0;              // Take Profit level (in points)
input int             Signal_Expiration    =1;                 // Expiration of pending orders (in bars)
input bool            Signal__BuyPosOpen   =true;              // 3LineBreak() Permission to buy
input bool            Signal__SellPosOpen  =true;              // 3LineBreak() Permission to sell
input bool            Signal__BuyPosClose  =true;              // 3LineBreak() Permission to exit a long position
input bool            Signal__SellPosClose =true;              // 3LineBreak() Permission to exit a short position
input ENUM_TIMEFRAMES Signal__Ind_Timeframe=PERIOD_H4;         // 3LineBreak() Timeframe
input int             Signal__period       =3;                 // 3LineBreak() Indicator period
input uint            Signal__SignalBar    =1;                 // 3LineBreak() Bar index for entry signal
input double          Signal__Weight       =1.0;               // 3LineBreak() Weight [0...1.0]
//--- inputs for money
input double          Money_FixLot_Percent =10.0;              // Percent
input double          Money_FixLot_Lots    =0.1;               // Fixed volume
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(-1);
     }
//--- Creating signal
   CExpertSignal *signal=new CExpertSignal;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(-2);
     }
//---
   ExtExpert.InitSignal(signal);
   signal.ThresholdOpen(Signal_ThresholdOpen);
   signal.ThresholdClose(Signal_ThresholdClose);
   signal.PriceLevel(Signal_PriceLevel);
   signal.StopLevel(Signal_StopLevel);
   signal.TakeLevel(Signal_TakeLevel);
   signal.Expiration(Signal_Expiration);
//--- Creating filter C3LineBreakSignal
   C3LineBreakSignal *filter0=new C3LineBreakSignal;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(-3);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.BuyPosOpen(Signal__BuyPosOpen);
   filter0.SellPosOpen(Signal__SellPosOpen);
   filter0.BuyPosClose(Signal__BuyPosClose);
   filter0.SellPosClose(Signal__SellPosClose);
   filter0.Ind_Timeframe(Signal__Ind_Timeframe);
   filter0.period(Signal__period);
   filter0.SignalBar(Signal__SignalBar);
   filter0.Weight(Signal__Weight);
//--- Creation of trailing object
   CTrailingNone *trailing=new CTrailingNone;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(-4);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(-5);
     }
//--- Set trailing parameters
//--- Creation of money object
   CMoneyFixedLot *money=new CMoneyFixedLot;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(-6);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(-7);
     }
//--- Set money parameters
   money.Percent(Money_FixLot_Percent);
   money.Lots(Money_FixLot_Lots);
//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(-8);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(-9);
     }
//--- ok
   return(0);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+
