//+------------------------------------------------------------------+
//|                                         TrailingParabolicSAR.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Expert\Expert.mqh>
#include <Expert\Trailing\TrailingParabolicSAR.mqh>
//---
CTrade            m_trade;                      // trading object
CSymbolInfo       m_symbol;                     // symbol info object
CPositionInfo     m_position;                   // trade position object
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for trailing
input double InpLots                      =0.01;  // Lots
input double Trailing_ParabolicSAR_Step   =0.02;  // Speed increment
input double Trailing_ParabolicSAR_Maximum=0.2;   // Maximum rate
//---
bool         Expert_EveryTick=false;
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
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,0))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(-1);
     }
//--- Creation of trailing object
   CTrailingPSAR *trailing=new CTrailingPSAR;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set trailing parameters
   trailing.Step(Trailing_ParabolicSAR_Step);
   trailing.Maximum(Trailing_ParabolicSAR_Maximum);
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//---
   bool res=false;
     {
      ObjectCreate(0,"BUY",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"BUY",OBJPROP_XDISTANCE,ChartGetInteger(0,CHART_WIDTH_IN_PIXELS)-102);
      ObjectSetInteger(0,"BUY",OBJPROP_YDISTANCE,37);
      ObjectSetString(0,"BUY",OBJPROP_TEXT,"BUY");
      ObjectSetInteger(0,"BUY",OBJPROP_BGCOLOR,clrMediumSeaGreen);

      ObjectCreate(0,"SELL",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"SELL",OBJPROP_XDISTANCE,ChartGetInteger(0,CHART_WIDTH_IN_PIXELS)-50);
      ObjectSetInteger(0,"SELL",OBJPROP_YDISTANCE,37);
      ObjectSetString(0,"SELL",OBJPROP_TEXT,"SELL");
      ObjectSetInteger(0,"SELL",OBJPROP_BGCOLOR,clrDarkOrange);
     }
   res=true;
//--- ok
   return(INIT_SUCCEEDED);
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
//--- 
   if(ObjectGetInteger(0,"BUY",OBJPROP_STATE)!=0)
     {
      ObjectSetInteger(0,"BUY",OBJPROP_STATE,0);
      //--- check for long position (BUY) possibility
      if(LongOpened())
         return;
     }
   if(ObjectGetInteger(0,"SELL",OBJPROP_STATE)!=0)
     {
      ObjectSetInteger(0,"SELL",OBJPROP_STATE,0);
      //--- check for short position (SELL) possibility
      if(ShortOpened())
         return;
     }
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
//| Check for long position opening                                  |
//+------------------------------------------------------------------+
bool LongOpened(void)
  {
   bool res=false;
//--- check for long position (BUY) possibility
     {
      double price=m_symbol.Ask();
        {
         //--- open position
         if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,InpLots,price,0.0,0.0))
            printf("Position by %s to be opened",Symbol());
         else
           {
            printf("Error opening BUY position by %s : '%s'",Symbol(),m_trade.ResultComment());
            printf("Open parameters : price=%f,TP=%f",price,0.0);
           }
        }
      //--- in any case we must exit from expert
      res=true;
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for short position opening                                 |
//+------------------------------------------------------------------+
bool ShortOpened(void)
  {
   bool res=false;
//--- check for short position (SELL) possibility
     {
      double price=m_symbol.Bid();
        {
         //--- open position
         if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,InpLots,price,0.0,0.0))
            printf("Position by %s to be opened",Symbol());
         else
           {
            printf("Error opening SELL position by %s : '%s'",Symbol(),m_trade.ResultComment());
            printf("Open parameters : price=%f,TP=%f",price,0.0);
           }
        }
      //--- in any case we must exit from expert
      res=true;
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
