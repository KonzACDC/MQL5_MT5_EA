//+------------------------------------------------------------------+
//|                                          Sample_TrailingStop.mq5 |
//|                                        MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Sample_TrailingStop.mqh> // include Trailing Stop class

//--- input parameters
input double   SARStep     =  0.02;    // Step of Parabolic
input double   SARMaximum  =  0.02;    // Maximum of Parabolic
input int      NRTRPeriod  =  40;      // NRTR period
input double   NRTRK       =  2;       // NRTR factor

string Symbols[]={"EURUSD","GBPUSD","USDCHF","USDJPY"};

CParabolicStop *SARTrailing[];
CNRTRStop *NRTRTrailing[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArrayResize(SARTrailing,ArraySize(Symbols));  // resize according to number of used symbols
   ArrayResize(NRTRTrailing,ArraySize(Symbols)); // resize according to number of used symbols   
   for(int i=0;i<ArraySize(Symbols);i++)
     { // for all symbols
      SARTrailing[i]=new CParabolicStop(); // create CParabolicStop class instance
      SARTrailing[i].Init(Symbols[i],PERIOD_CURRENT,false,true,true,5,15+i*17,Silver,Blue); // initialization of CParabolicStop class instance 
      if(!SARTrailing[i].SetParameters(SARStep,SARMaximum))
        { // setting parameters of CParabolicStop class instance 
         Alert("trailing error");
         return(-1);
        }
      SARTrailing[i].StartTimer(); // start timer
      //----
      NRTRTrailing[i]=new CNRTRStop(); // create CNRTRStop class instance
      NRTRTrailing[i].Init(Symbols[i],PERIOD_CURRENT,false,true,true,127,15+i*17,Silver,Blue); // initialization of CNRTRStop class instance 
      if(!NRTRTrailing[i].SetParameters(NRTRPeriod,NRTRK))
        { // setting parameters of CNRTRcStop class instance 
         Alert("trailing error");
         return(-1);
        }
      NRTRTrailing[i].StartTimer(); // start timer         
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   for(int i=0;i<ArraySize(Symbols);i++)
     {
      SARTrailing[i].Deinit();
      NRTRTrailing[i].Deinit();
      delete(SARTrailing[i]);
      delete(NRTRTrailing[i]);
     }

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   for(int i=0;i<ArraySize(Symbols);i++)
     {
      SARTrailing[i].DoStoploss();
      NRTRTrailing[i].DoStoploss();
     }

  }
//+------------------------------------------------------------------+

void OnTimer()
  {
   for(int i=0;i<ArraySize(Symbols);i++)
     {
      SARTrailing[i].Refresh();
      NRTRTrailing[i].Refresh();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam
                  )
  {

   for(int i=0;i<ArraySize(Symbols);i++)
     {
      SARTrailing[i].EventHandle(id,lparam,dparam,sparam);
      NRTRTrailing[i].EventHandle(id,lparam,dparam,sparam);
     }
  }
//+------------------------------------------------------------------+
