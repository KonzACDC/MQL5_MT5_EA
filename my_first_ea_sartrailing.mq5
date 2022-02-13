//+------------------------------------------------------------------+
//|                                      My_First_EA_SARTrailing.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Sample_TrailingStop.mqh> // include Trailing Stop class

//--- input parameters
input int    StopLoss           =    30; // Stop Loss
input int    TakeProfit         =   100; // Take Profit
input int    ADX_Period         =     8; // ADX period
input int    MA_Period          =     8; // Moving Average period
input int    EA_Magic           = 12345; // Magic Number of Expert Advisor
input double Adx_Min            =  22.0; // ADX minimal value
input double Lot                =   0.1; // Number of lots for trade
input double TrailingSARStep    =  0.02; // Step of Parabolic
input double TrailingSARMaximum =   0.2; // Maximum of Parabolic

//--- global variables
int    adxHandle;                // ADX indicator handle
int    maHandle;                 // Moving Average indicator handle
double plsDI[],minDI[],adxVal[]; // dynamic arrays to store numeric values of +DI, -DI and ADX for each bar
double maVal[];                  // dynamic array to store values of Moving Average indicator for each bar
double p_close;                  // variable to store  value of the Close bar
int    STP,TKP;                  // these variables will be used for Stop Loss and Take Profit values

CParabolicStop Trailing; // create class instance 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- Initialize (set basic parameters)
   Trailing.Init(_Symbol,PERIOD_CURRENT,true,true,false); 
   //--- Set parameters of used trailing stop type
   if(!Trailing.SetParameters(TrailingSARStep,TrailingSARMaximum))
     { 
      Alert("trailing error");
      return(-1);
     }
   Trailing.StartTimer(); // Start timer
   Trailing.On();         // Turn On

//--- Is the number of bars sufficient for work?
   //--- total number of bars on chart is less than 60?
   if(Bars(_Symbol,_Period)<60) 
     {
      Alert("There are less that 60 bars on chart, Expert Advisor won't work!");
      return(-1);
     }
//--- Get ADX indicator handle
   adxHandle=iADX(NULL,0,ADX_Period);
//--- Get Moving Average indicator handle
   maHandle=iMA(_Symbol,_Period,MA_Period,0,MODE_EMA,PRICE_CLOSE);
//--- Must check, if Invalid Handle values were returned
   if(adxHandle<0 || maHandle<0)
     {
      Alert("Error when creating indicators - error #",GetLastError(),"!");
      return(-1);
     }

//--- To work with brokers that use the 5 digit quotes
// multiply SL and TP values by 10
   STP = StopLoss;
   TKP = TakeProfit;
   if(_Digits==5 || _Digits==3)
     {
      STP = STP*10;
      TKP = TKP*10;
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   Trailing.Refresh();
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Release indicators handles
   IndicatorRelease(adxHandle);
   IndicatorRelease(maHandle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   Trailing.DoStoploss();

// To store value of bar time we use the Old_Time static variable.
// On each OnTick we will compare the time of current bar against the saved time.
// If they are not equal, it means that a new bar began to plot.

   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;

// copy the current bar time into the New_Time[0] element
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0)                 // OK, successfully copied
     {
      if(Old_Time!=New_Time[0]) // if the old time is not equal to
        {
         IsNewBar=true;         // new bar
         if(MQL5InfoInteger(MQL5_DEBUGGING)) Print("New bar",New_Time[0],"Old bar",Old_Time);
         Old_Time=New_Time[0];  // save the bar time
        }
     }
   else
     {
      Alert("Error when copying time - error #",GetLastError());
      ResetLastError();
      return;
     }

//--- Expert Adviser must check conditions of new trade operation commitment only on new bar
   if(IsNewBar==false)
     {
      return;
     }

//--- Do we have enough bars on the chart for work
   int Mybars=Bars(_Symbol,_Period);
   if(Mybars<60) // if total number of bars is less than 60
     {
      Alert("There are less that 60 bars on chart, Expert Advisor won't work!");
      return;
     }

//--- Declare structures, that will be used for trade
   MqlTick latest_price;       // Will be used for current quotes
   MqlTradeRequest mrequest;   // Will be used to send trade requests
   MqlTradeResult mresult;     // Will be used to receive results of trade requests
   MqlRates mrate[];           // Will store prices, volumes and spread for each bar

//--- Set the indexing in arrays of quotes and indicators  
//    as in timeseries

//--- array of quotes
   ArraySetAsSeries(mrate,true);
//--- array of ADX indicator values
   ArraySetAsSeries(adxVal,true);
//--- array of MA-8 indicator values
   ArraySetAsSeries(maVal,true);

//--- Get current value of quote into structure of the MqlTick type
   if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error when receiving the latest quotes - error#",GetLastError(),"!");
      return;
     }

//--- Get history data of the last 3 bars
   if(CopyRates(_Symbol,_Period,0,3,mrate)<0)
     {
      Alert("Error when compiling history data - error#",GetLastError(),"!");
      return;
     }

//--- Copy the new values of our indicators to buffers (arrays) using the handle
   if(CopyBuffer(adxHandle,0,0,3,adxVal)<0 || CopyBuffer(adxHandle,1,0,3,plsDI)<0
      || CopyBuffer(adxHandle,2,0,3,minDI)<0)
     {
      Alert("Error when copying ADX indicator buffers - error #",GetLastError(),"!");
      return;
     }
   if(CopyBuffer(maHandle,0,0,3,maVal)<0)
     {
      Alert("Error when copying Moving Average indicator buffers - error #",GetLastError(),"!");
      return;
     }
//--- Are there any open positions?
   bool Buy_opened=false;  // variables that will store info 
   bool Sell_opened=false; // about any corresponding opened positions

   // there is opened position
   if(PositionSelect(_Symbol)==true) 
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         Buy_opened=true;  // this is long position
        }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         Sell_opened=true; // this is short position
        }
     }

// Copy the current close price of the previous bar (this bar 1)
   p_close=mrate[1].close;  // the close price of previous bar

//+-------------------------------------------------------------------+
//| 1. Check condition for buy: MA-8 is growing,                    |
//| previous close price of bar is more than MA-8, ADX > 22, +DI > -DI |
//+-------------------------------------------------------------------+

//--- declare variables of bool type, they will be used to check conditions for Buy
   bool Buy_Condition_1=(maVal[0]>maVal[1]) && (maVal[1]>maVal[2]); // MA-8 is growing
   bool Buy_Condition_2 = (p_close > maVal[1]);                     // previous close price is higher than MA-8
   bool Buy_Condition_3 = (adxVal[0]>Adx_Min);                      // ADX current value is more than minimal (22)
   bool Buy_Condition_4 = (plsDI[0]>minDI[0]);                      // +DI is more than -DI

//--- combine all together
   if(Buy_Condition_1 && Buy_Condition_2)
     {
      if(Buy_Condition_3 && Buy_Condition_4)
        {
         // is there currently any opened position for Buy?
         if(Buy_opened)
           {
            Alert("There is a position for Buy!!!");
            return;    // do not add to opened position for Buy
           }
         mrequest.action = TRADE_ACTION_DEAL;                                  // instant execution
         mrequest.price = NormalizeDouble(latest_price.ask,_Digits);           // last ask price
         mrequest.sl = NormalizeDouble(latest_price.ask - STP*_Point,_Digits); // Stop Loss
         mrequest.tp = NormalizeDouble(latest_price.ask + TKP*_Point,_Digits); // Take Profit
         mrequest.symbol = _Symbol;                                            // symbol
         mrequest.volume = Lot;                                                // number of lots for trade
         mrequest.magic = EA_Magic;                                            // Magic Number
         mrequest.type = ORDER_TYPE_BUY;                                       // order for Buy
         mrequest.type_filling = ORDER_FILLING_FOK;                            // type of order filling - all or none
         mrequest.deviation=100;                                               // deviation from current price
         //--- send order
         OrderSend(mrequest,mresult);
         //--- analyze the return code of trade server
         if(mresult.retcode==10009 || mresult.retcode==10008) //request completed or order successfully placed
           {
            Alert("The Buy order successfully placed, order ticket #",mresult.order,"!!");
           }
         else
           {
            Alert("Request to place the Buy order was not completed - error code#",GetLastError());
            return;
           }
        }
     }
//+-------------------------------------------------------------------+
//| 2. Check condition for Buy: MA-8 is falling                 |
//| previous close price of bar is less than MA-8, ADX > 22, -DI > +DI |
//+-------------------------------------------------------------------+

//--- declare variables of bool type, they will be used to check conditions for Sell
   bool Sell_Condition_1 = (maVal[0]<maVal[1]) && (maVal[1]<maVal[2]);  // MA-8 is falling
   bool Sell_Condition_2 = (p_close <maVal[1]);                         // previous close price is lower than MA-8
   bool Sell_Condition_3 = (adxVal[0]>Adx_Min);                         // ADX current value is more than the set (22)
   bool Sell_Condition_4 = (plsDI[0]<minDI[0]);                         // -DI is more than +DI

//--- combine all together
   if(Sell_Condition_1 && Sell_Condition_2)
     {
      if(Sell_Condition_3 && Sell_Condition_4)
        {
         // is there currently any opened position for Sell?
         if(Sell_opened)
           {
            Alert("There is a position for Sell!!!");
            return;    // do not add to opened position for Sell
           }
         mrequest.action = TRADE_ACTION_DEAL;                                  // instant execution
         mrequest.price = NormalizeDouble(latest_price.bid,_Digits);           // last Bid price
         mrequest.sl = NormalizeDouble(latest_price.bid + STP*_Point,_Digits); // Stop Loss
         mrequest.tp = NormalizeDouble(latest_price.bid - TKP*_Point,_Digits); // Take Profit
         mrequest.symbol = _Symbol;                                            // symbol
         mrequest.volume = Lot;                                                // number of lots for trade
         mrequest.magic = EA_Magic;                                            // Magic Number
         mrequest.type= ORDER_TYPE_SELL;                                       // order for sell
         mrequest.type_filling = ORDER_FILLING_FOK;                            // type of order filling - all or none
         mrequest.deviation=100;                                               // deviation from current price
         //--- send order
         OrderSend(mrequest,mresult);
         //--- analyze the return code of trade server
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
           {
            Alert("The Sell order successfully placed, order ticket #",mresult.order,"!!");
           }
         else
           {
            Alert("Request to place the Sell order was not completed - error code#",GetLastError());
            return;
           }
        }
     }
   return;
  }
//+------------------------------------------------------------------+
