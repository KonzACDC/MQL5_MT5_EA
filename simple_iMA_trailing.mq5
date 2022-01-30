//+------------------------------------------------------------------+
//|                                          Simple iMA Trailing.mq5 |
//|                              Copyright © 2020, Vladimir Karputov |
//|                     https://www.mql5.com/ru/market/product/43516 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2020, Vladimir Karputov"
#property link      "https://www.mql5.com/ru/market/product/43516"
#property version   "1.000"
#property description "Trailing Stop in Points (1.00045-1.00055=10 points)"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
//---
CPositionInfo  m_position;                   // object of CPositionInfo class
CTrade         m_trade;                      // object of CTrade class
CSymbolInfo    m_symbol;                     // object of CSymbolInfo class
//--- input parameters
input group             "Trailing"
input uint                 InpTrailingStop      = 10;          // Trailing Stop (min distance from price to Stop Loss)
input group             "MA"
input int                  Inp_MA_ma_period     = 12;          // MA: averaging period
input int                  Inp_MA_ma_shift      = 0;           // MA: horizontal shift
input ENUM_MA_METHOD       Inp_MA_ma_method     = MODE_SMA;    // MA: smoothing type
input ENUM_APPLIED_PRICE   Inp_MA_applied_price = PRICE_CLOSE; // MA: type of price
input group             "Additional features"
input bool                 InpPrintLog          = true;       // Print log
input ulong                InpDeviation         = 10;          // Deviation
input ulong                InpMagic             = 11828516;    // Magic number
//---
double   m_trailing_stop            = 0.0;      // Trailing Stop              -> double

int      handle_iMA;                            // variable for storing the handle of the iMA indicator

datetime m_prev_bars                = 0;        // "0" -> D'1970.01.01 00:00';
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ResetLastError();
   if(!m_symbol.Name(Symbol())) // sets symbol name
     {
      Print(__FILE__," ",__FUNCTION__,", ERROR: CSymbolInfo.Name");
      return(INIT_FAILED);
     }
   RefreshRates();
//---
   m_trade.SetExpertMagicNumber(InpMagic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(InpDeviation);
//---
   m_trailing_stop            = InpTrailingStop             * m_symbol.Point();
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),Period(),Inp_MA_ma_period,Inp_MA_ma_shift,
                  Inp_MA_ma_method,Inp_MA_applied_price);
//--- if the handle is not created
   if(handle_iMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- we work only at the time of the birth of new bar
   datetime time_0=iTime(m_symbol.Name(),Period(),0);
   if(time_0==m_prev_bars)
      return;
   m_prev_bars=time_0;
   if(!RefreshRates())
     {
      m_prev_bars=0;
      return;
     }
   Trailing();
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print(__FILE__," ",__FUNCTION__,", ERROR: ","RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
     {
      Print(__FILE__," ",__FUNCTION__,", ERROR: ","Ask == 0.0 OR Bid == 0.0");
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//|   InpTrailingStop: min distance from price to Stop Loss          |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(InpTrailingStop==0)
      return;
   double ma[];
   ArraySetAsSeries(ma,true);
   int start_pos=0,count=3;
   if(!iGetArray(handle_iMA,0,start_pos,count,ma))
     {
      m_prev_bars=0;
      return;
     }
//---
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
           {
            double pos_price_current   = m_position.PriceCurrent();
            double pos_price_open      = m_position.PriceOpen();
            double stop_loss           = m_position.StopLoss();
            double take_profit         = m_position.TakeProfit();
            double ask                 = m_symbol.Ask();
            double bid                 = m_symbol.Bid();
            //---
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(pos_price_current>pos_price_open+m_trailing_stop)
                  if(pos_price_current>ma[1])
                     if(stop_loss<ma[1])
                        if(!CompareDoubles(stop_loss,ma[1],Digits(),Point()))
                          {
                           if(!m_trade.PositionModify(m_position.Ticket(),m_symbol.NormalizePrice(ma[1]),take_profit))
                              if(InpPrintLog)
                                 Print(__FILE__," ",__FUNCTION__,", ERROR: ","Modify BUY ",m_position.Ticket(),
                                       " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                       ", description of result: ",m_trade.ResultRetcodeDescription());
                           continue;
                          }
              }
            else
              {
               if(pos_price_current<pos_price_open-m_trailing_stop)
                  if(pos_price_current<ma[1])
                     if((stop_loss>ma[1]) || (stop_loss==0))
                        if(!CompareDoubles(stop_loss,ma[1],Digits(),Point()))
                          {
                           if(!m_trade.PositionModify(m_position.Ticket(),m_symbol.NormalizePrice(ma[1]),take_profit))
                              if(InpPrintLog)
                                 Print(__FILE__," ",__FUNCTION__,", ERROR: ","Modify SELL ",m_position.Ticket(),
                                       " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                       ", description of result: ",m_trade.ResultRetcodeDescription());
                          }
              }
           }
  }
//+------------------------------------------------------------------+
//| Compare doubles                                                  |
//+------------------------------------------------------------------+
bool CompareDoubles(double number1,double number2,int digits,double points)
  {
   if(MathAbs(NormalizeDouble(number1-number2,digits))<=points)
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+
//| Get value of buffers                                             |
//+------------------------------------------------------------------+
bool iGetArray(const int handle,const int buffer,const int start_pos,
               const int count,double &arr_buffer[])
  {
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      if(InpPrintLog)
         PrintFormat("ERROR! EA: %s, FUNCTION: %s, this a no dynamic array!",__FILE__,__FUNCTION__);
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
      if(InpPrintLog)
         PrintFormat("ERROR! EA: %s, FUNCTION: %s, amount to copy: %d, copied: %d, error code %d",
                     __FILE__,__FUNCTION__,count,copied,GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
     }
   return(result);
  }
//+------------------------------------------------------------------+
