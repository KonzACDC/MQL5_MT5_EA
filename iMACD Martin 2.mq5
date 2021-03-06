//+------------------------------------------------------------------+
//|                                               iMACD Martin 2.mq5 |
//|                         Copyright © 2020-2021, Vladimir Karputov |
//|                     https://www.mql5.com/ru/market/product/43516 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2020-2021, Vladimir Karputov"
#property link      "https://www.mql5.com/ru/market/product/43516"
#property version   "2.000"
#property description "Signal Reverse"
#property description "Signal Crossover of the main and signal line"
#property description "Signal Crossing the zero level"
/*
   barabashkakvn Trading engine 3.156
*/
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
//---
CPositionInfo  m_position;                   // object of CPositionInfo class
CTrade         m_trade;                      // object of CTrade class
CSymbolInfo    m_symbol;                     // object of CSymbolInfo class
CAccountInfo   m_account;                    // object of CAccountInfo class
CDealInfo      m_deal;                       // object of CDealInfo class
//+------------------------------------------------------------------+
//| Enum Signal 'Reverse'                                            |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_REVERSE
  {
   reverse=0,        // Reverse
   reverse_zero=1,   // Reverse zero control
   reverse_off=2,    // Reverse off
  };
//+------------------------------------------------------------------+
//| Enum Signal 'Crossover'                                          |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_CROSSOVER
  {
   crossover=0,      // Crossover
   crossover_zero=1, // Crossover zero control
   crossover_off=2,  // Crossover off
  };
//+------------------------------------------------------------------+
//| Enum Signal 'Crossing zero'                                      |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_CROSSING
  {
   crossing=0,       // Crossing zero
   crossing_off=1,   // Crossing zero off
  };
//--- input parameters
input group             "Trading settings"
input ENUM_TIMEFRAMES      InpWorkingPeriod        = PERIOD_CURRENT; // Working timeframe
input bool                 InpBarCurrent           = false;          // Bar current ('true'->#0, 'false'->#1)
input group             "Position size management (lot calculation)"
input double               InpLots                 = 0.01;           // Start lots
input group             "MACD"
input int                     Inp_MACD_fast_ema_period= 12;             // MACD: period for Fast average calculation
input int                     Inp_MACD_slow_ema_period= 26;             // MACD: period for Slow average calculation
input int                     Inp_MACD_signal_period  = 9;              // MACD: period for their difference averaging
input ENUM_APPLIED_PRICE      Inp_MACD_applied_price  = PRICE_CLOSE;    // MACD: type of price
input ENUM_SIGNAL_REVERSE     InpMACDSignalReverse    = reverse_zero;   // MACD Signal Reverse:
input ENUM_SIGNAL_CROSSOVER   InpMACDSignalCrossover  = crossover_zero; // MACD Signal Crossover:
input ENUM_SIGNAL_CROSSING    InpMACDSignalCrossing   = crossing;       // MACD Signal Crossing:
input group             "Martingale"
input double               InpProfitTarget         = 30.0;           // Profit target
input double               InpPositionIncreaseRatio= 1.6;            // Position Increase Ratio
input ushort               InpMinimumStep          = 150;            // Minimum step between positions ('0' -> off)
input double               InpMaximumPositionVolume= 1.5;            // Maximum position volume
input double               InpMaximumTotalVolume   = 6.31;           // The maximum total volume of positions
input group             "Notification at global stop"
input bool                 InpMail                 = true;           // Send an email
input bool                 InpNotification         = true;           // Send push notifications
input group             "Additional features"
input bool                 InpPrintLog             = true;           // Print log
input ulong                InpMagic                = 472065132;      // Magic number
//---
double   m_minimum_step             = 0.0;      // Minimum step between positions   -> double

int      handle_iMACD;                          // variable for storing the handle of the iMACD indicatorr

bool     m_need_close_all           = false;    // close all positions
datetime m_prev_bars                = 0;        // "0" -> D'1970.01.01 00:00';
datetime m_last_deal_in             = 0;        // "0" -> D'1970.01.01 00:00';
int      m_bar_current              = 0;
bool     m_global_stop              = false;    // global stop

ENUM_DEAL_TYPE m_last_deal_in_type  = WRONG_VALUE; // last deal IN type
double   m_last_deal_in_volume      = 0.0;         // last deal IN volume
double   m_last_deal_in_price       = 0.0;         // last deal IN price
bool     m_init_error               = false;       // error on InInit
//--- the tactic is this: for positions we strictly monitor the result, ***
//+------------------------------------------------------------------+
//| Structure Positions                                              |
//+------------------------------------------------------------------+
struct STRUCT_POSITION
  {
   ENUM_POSITION_TYPE pos_type;              // position type
   double            volume;                 // position volume (if "0.0" -> the lot is "Money management")
   bool              waiting_transaction;    // waiting transaction, "true" -> it's forbidden to trade, we expect a transaction
   ulong             waiting_order_ticket;   // waiting order ticket, ticket of the expected order
   bool              transaction_confirmed;  // transaction confirmed, "true" -> transaction confirmed
   //--- Constructor
                     STRUCT_POSITION()
     {
      pos_type                   = WRONG_VALUE;
      volume                     = 0.0;
      waiting_transaction        = false;
      waiting_order_ticket       = 0;
      transaction_confirmed      = false;
     }
  };
STRUCT_POSITION SPosition[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- forced initialization of variables
   m_minimum_step             = 0.0;         // Minimum step between positions   -> double
   m_need_close_all           = false;       // close all positions
   m_prev_bars                = 0;           // "0" -> D'1970.01.01 00:00';
   m_last_deal_in             = 0;           // "0" -> D'1970.01.01 00:00';
   m_bar_current              = 0;
   m_global_stop              = false;       // global stop
   m_last_deal_in_type        = WRONG_VALUE; // last deal IN type
   m_last_deal_in_volume      = 0.0;         // last deal IN volume
   m_last_deal_in_price       = 0.0;         // last deal IN price
   m_init_error               = false;       // error on InInit
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
   m_trade.SetDeviationInPoints(10);
//---
   m_minimum_step             = InpMinimumStep              * m_symbol.Point();
//--- check the input parameter "Lots"
   string err_text="";
   if(!CheckVolumeValue(InpLots,err_text))
     {
      if(MQLInfoInteger(MQL_TESTER)) // when testing, we will only output to the log about incorrect input parameters
         Print(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
      else // if the Expert Advisor is run on the chart, tell the user about the error
         Alert(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
      //---
      m_init_error=true;
      return(INIT_SUCCEEDED);
     }
//--- create handle of the indicator iMACD
   handle_iMACD=iMACD(m_symbol.Name(),InpWorkingPeriod,Inp_MACD_fast_ema_period,Inp_MACD_slow_ema_period,
                      Inp_MACD_signal_period,Inp_MACD_applied_price);
//--- if the handle is not created
   if(handle_iMACD==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(InpWorkingPeriod),
                  GetLastError());
      //--- the indicator is stopped early
      m_init_error=true;
      return(INIT_SUCCEEDED);
     }
//---
   m_bar_current=(InpBarCurrent)?0:1;
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
   if(m_init_error)
      return;
//---
   if(m_need_close_all)
     {
      if(IsPositionExists())
        {
         CloseAllPositions();
         return;
        }
      else
        {
         m_need_close_all=false;
         m_last_deal_in_type=WRONG_VALUE;
         m_last_deal_in_volume=0.0;
         m_last_deal_in_price=0.0;
        }
     }
//---
   if(m_global_stop)
      return;
//---
   if(ProfitAllPositions()>=InpProfitTarget)
     {
      m_need_close_all=true;
      return;
     }
//---
   int size_need_position=ArraySize(SPosition);
   if(size_need_position>0)
     {
      for(int i=size_need_position-1; i>=0; i--)
        {
         if(SPosition[i].waiting_transaction)
           {
            if(!SPosition[i].transaction_confirmed)
              {
               if(InpPrintLog)
                  Print(__FILE__," ",__FUNCTION__,", OK: ","transaction_confirmed: ",SPosition[i].transaction_confirmed);
               return;
              }
            else
               if(SPosition[i].transaction_confirmed)
                 {
                  ArrayRemove(SPosition,i,1);
                  return;
                 }
           }
         //---
         SPosition[i].waiting_transaction=true;
         OpenPosition(i);
         return;
        }
     }
//---
   if(InpBarCurrent) // search for trading signals every ticks
     {
      if(!RefreshRates())
         return;
      if(!SearchTradingSignals())
         return;
     }
   else // we work only at the time of the birth of new bar
     {
      datetime time_0=iTime(m_symbol.Name(),InpWorkingPeriod,0);
      if(time_0==m_prev_bars)
         return;
      m_prev_bars=time_0;
      if(!RefreshRates())
        {
         m_prev_bars=0;
         return;
        }
      //--- search for trading signals
      if(!SearchTradingSignals())
        {
         m_prev_bars=0;
         return;
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//--- get transaction type as enumeration value
   ENUM_TRADE_TRANSACTION_TYPE type=trans.type;
//--- if transaction is result of addition of the transaction in history
   if(type==TRADE_TRANSACTION_DEAL_ADD)
     {
      ResetLastError();
      if(HistoryDealSelect(trans.deal))
         m_deal.Ticket(trans.deal);
      else
        {
         Print(__FILE__," ",__FUNCTION__,", ERROR: ","HistoryDealSelect(",trans.deal,") error: ",GetLastError());
         return;
        }
      if(m_deal.Symbol()==m_symbol.Name() && m_deal.Magic()==InpMagic)
        {
         if(m_deal.DealType()==DEAL_TYPE_BUY || m_deal.DealType()==DEAL_TYPE_SELL)
           {
            if(m_deal.Entry()==DEAL_ENTRY_IN || m_deal.Entry()==DEAL_ENTRY_INOUT)
              {
               m_last_deal_in=iTime(m_symbol.Name(),InpWorkingPeriod,0);
               m_last_deal_in_type=(ENUM_DEAL_TYPE)m_deal.DealType();
               m_last_deal_in_volume=m_deal.Volume();
               m_last_deal_in_price=m_deal.Price();
              }
            int size_need_position=ArraySize(SPosition);
            if(size_need_position>0)
              {
               for(int i=0; i<size_need_position; i++)
                 {
                  if(SPosition[i].waiting_transaction)
                     if(SPosition[i].waiting_order_ticket==m_deal.Order())
                       {
                        Print(__FUNCTION__," Transaction confirmed");
                        SPosition[i].transaction_confirmed=true;
                        break;
                       }
                 }
              }
           }
        }
     }
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
//| Check the correctness of the position volume                     |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol.LotsMin();
   if(volume<min_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем меньше минимально допустимого SYMBOL_VOLUME_MIN=%.2f",min_volume);
      else
         error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем больше максимально допустимого SYMBOL_VOLUME_MAX=%.2f",max_volume);
      else
         error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем не кратен минимальному шагу SYMBOL_VOLUME_STEP=%.2f, ближайший правильный объем %.2f",
                                        volume_step,ratio*volume_step);
      else
         error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                        volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Lot Check                                                        |
//+------------------------------------------------------------------+
double LotCheck(double lots,CSymbolInfo &symbol)
  {
//--- calculate maximum volume
   double volume=NormalizeDouble(lots,2);
   double stepvol=symbol.LotsStep();
   if(stepvol>0.0)
      volume=stepvol*MathFloor(volume/stepvol);
//---
   double minvol=symbol.LotsMin();
   if(volume<minvol)
      volume=0.0;
//---
   double maxvol=symbol.LotsMax();
   if(volume>maxvol)
      volume=maxvol;
//---
   return(volume);
  }
//+------------------------------------------------------------------+
//| Open position                                                    |
//+------------------------------------------------------------------+
void OpenPosition(const int index)
  {
   if(!RefreshRates())
      return;
//--- buy
   if(SPosition[index].pos_type==POSITION_TYPE_BUY)
     {
      OpenBuy(index);
      return;
     }
//--- sell
   if(SPosition[index].pos_type==POSITION_TYPE_SELL)
     {
      OpenSell(index);
      return;
     }
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(const int index)
  {
   double sl=0.0;
   double tp=0.0;
   double long_lot=0.0;
   if(SPosition[index].volume>0.0)
      long_lot=SPosition[index].volume;
   else
     {
      ArrayRemove(SPosition,index,1);
      return;
     }
//---
   if(m_symbol.LotsLimit()>0.0)
     {
      int      count_buys           = 0;
      double   volume_buys          = 0.0;
      double   volume_biggest_buys  = 0.0;
      int      count_sells          = 0;
      double   volume_sells         = 0.0;
      double   volume_biggest_sells = 0.0;
      CalculateAllPositions(count_buys,volume_buys,volume_biggest_buys,
                            count_sells,volume_sells,volume_biggest_sells,
                            true);
      if(volume_buys+volume_sells+long_lot>m_symbol.LotsLimit())
        {
         ArrayRemove(SPosition,index,1);
         if(InpPrintLog)
            Print(__FILE__," ",__FUNCTION__,", ERROR: ","#0 Buy, Volume Buy (",DoubleToString(volume_buys,2),
                  ") + Volume Sell (",DoubleToString(volume_sells,2),
                  ") + Volume long (",DoubleToString(long_lot,2),
                  ") > Lots Limit (",DoubleToString(m_symbol.LotsLimit(),2),")");
         return;
        }
     }
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check=m_account.FreeMarginCheck(m_symbol.Name(),
                            ORDER_TYPE_BUY,
                            long_lot,
                            m_symbol.Ask());
   double margin_check=m_account.MarginCheck(m_symbol.Name(),
                       ORDER_TYPE_BUY,
                       long_lot,
                       m_symbol.Ask());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Buy(long_lot,m_symbol.Name(),
                     m_symbol.Ask(),sl,tp)) // CTrade::Buy -> "true"
        {
         if(m_trade.ResultDeal()==0)
           {
            if(m_trade.ResultRetcode()==10009) // trade order went to the exchange
              {
               SPosition[index].waiting_transaction=true;
               SPosition[index].waiting_order_ticket=m_trade.ResultOrder();
              }
            else
              {
               SPosition[index].waiting_transaction=false;
               if(InpPrintLog)
                  Print(__FILE__," ",__FUNCTION__,", ERROR: ","#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of result: ",m_trade.ResultRetcodeDescription());
              }
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            if(m_trade.ResultRetcode()==10009)
              {
               SPosition[index].waiting_transaction=true;
               SPosition[index].waiting_order_ticket=m_trade.ResultOrder();
              }
            else
              {
               SPosition[index].waiting_transaction=false;
               if(InpPrintLog)
                  Print(__FILE__," ",__FUNCTION__,", OK: ","#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of result: ",m_trade.ResultRetcodeDescription());
              }
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         SPosition[index].waiting_transaction=false;
         if(InpPrintLog)
            Print(__FILE__," ",__FUNCTION__,", ERROR: ","#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
         if(InpPrintLog)
            PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      ArrayRemove(SPosition,index,1);
      if(InpPrintLog)
         Print(__FILE__," ",__FUNCTION__,", ERROR: ","Free Margin Check (",DoubleToString(free_margin_check,2),") <= Margin Check (",DoubleToString(margin_check,2),")");
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(const int index)
  {
   double sl=0.0;
   double tp=0.0;
   double short_lot=0.0;
   if(SPosition[index].volume>0.0)
      short_lot=SPosition[index].volume;
   else
     {
      ArrayRemove(SPosition,index,1);
      return;
     }
//---
   if(m_symbol.LotsLimit()>0.0)
     {
      int      count_buys           = 0;
      double   volume_buys          = 0.0;
      double   volume_biggest_buys  = 0.0;
      int      count_sells          = 0;
      double   volume_sells         = 0.0;
      double   volume_biggest_sells = 0.0;
      CalculateAllPositions(count_buys,volume_buys,volume_biggest_buys,
                            count_sells,volume_sells,volume_biggest_sells,
                            true);
      if(volume_buys+volume_sells+short_lot>m_symbol.LotsLimit())
        {
         ArrayRemove(SPosition,index,1);
         if(InpPrintLog)
            Print(__FILE__," ",__FUNCTION__,", ERROR: ","#0 Buy, Volume Buy (",DoubleToString(volume_buys,2),
                  ") + Volume Sell (",DoubleToString(volume_sells,2),
                  ") + Volume short (",DoubleToString(short_lot,2),
                  ") > Lots Limit (",DoubleToString(m_symbol.LotsLimit(),2),")");
         return;
        }
     }
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check=m_account.FreeMarginCheck(m_symbol.Name(),
                            ORDER_TYPE_SELL,
                            short_lot,
                            m_symbol.Bid());
   double margin_check=m_account.MarginCheck(m_symbol.Name(),
                       ORDER_TYPE_SELL,
                       short_lot,
                       m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Sell(short_lot,m_symbol.Name(),
                      m_symbol.Bid(),sl,tp)) // CTrade::Sell -> "true"
        {
         if(m_trade.ResultDeal()==0)
           {
            if(m_trade.ResultRetcode()==10009) // trade order went to the exchange
              {
               SPosition[index].waiting_transaction=true;
               SPosition[index].waiting_order_ticket=m_trade.ResultOrder();
              }
            else
              {
               SPosition[index].waiting_transaction=false;
               if(InpPrintLog)
                  Print(__FILE__," ",__FUNCTION__,", ERROR: ","#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of result: ",m_trade.ResultRetcodeDescription());
              }
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            if(m_trade.ResultRetcode()==10009)
              {
               SPosition[index].waiting_transaction=true;
               SPosition[index].waiting_order_ticket=m_trade.ResultOrder();
              }
            else
              {
               SPosition[index].waiting_transaction=false;
               if(InpPrintLog)
                  Print(__FILE__," ",__FUNCTION__,", OK: ","#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of result: ",m_trade.ResultRetcodeDescription());
              }
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         SPosition[index].waiting_transaction=false;
         if(InpPrintLog)
            Print(__FILE__," ",__FUNCTION__,", ERROR: ","#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
         if(InpPrintLog)
            PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      ArrayRemove(SPosition,index,1);
      if(InpPrintLog)
         Print(__FILE__," ",__FUNCTION__,", ERROR: ","Free Margin Check (",DoubleToString(free_margin_check,2),") <= Margin Check (",DoubleToString(margin_check,2),")");
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultTrade(CTrade &trade,CSymbolInfo &symbol)
  {
   Print(__FILE__," ",__FUNCTION__,", Symbol: ",symbol.Name()+", "+
         "Code of request result: "+IntegerToString(trade.ResultRetcode())+", "+
         "Code of request result as a string: "+trade.ResultRetcodeDescription(),
         "Trade execution mode: "+symbol.TradeExecutionDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal())+", "+
         "Order ticket: "+IntegerToString(trade.ResultOrder())+", "+
         "Order retcode external: "+IntegerToString(trade.ResultRetcodeExternal())+", "+
         "Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits())+", "+
         "Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits())+", "+
         "Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
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
//| Calculate all positions                                          |
//|  'lots_limit=true' - only for 'if(m_symbol.LotsLimit()>0.0)'     |
//+------------------------------------------------------------------+
void CalculateAllPositions(int &count_buys,double &volume_buys,double &volume_biggest_buys,
                           int &count_sells,double &volume_sells,double &volume_biggest_sells,
                           bool lots_limit=false)
  {
   count_buys  = 0;
   volume_buys   = 0.0;
   volume_biggest_buys  = 0.0;
   count_sells = 0;
   volume_sells  = 0.0;
   volume_biggest_sells = 0.0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && (lots_limit || (!lots_limit && m_position.Magic()==InpMagic)))
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               count_buys++;
               volume_buys+=m_position.Volume();
               if(m_position.Volume()>volume_biggest_buys)
                  volume_biggest_buys=m_position.Volume();
               continue;
              }
            else
               if(m_position.PositionType()==POSITION_TYPE_SELL)
                 {
                  count_sells++;
                  volume_sells+=m_position.Volume();
                  if(m_position.Volume()>volume_biggest_sells)
                     volume_biggest_sells=m_position.Volume();
                 }
           }
  }
//+------------------------------------------------------------------+
//| Search trading signals                                           |
//+------------------------------------------------------------------+
bool SearchTradingSignals(void)
  {
   if(iTime(m_symbol.Name(),InpWorkingPeriod,0)==m_last_deal_in) // on one bar - only one deal
      return(true);
   double main[],signal[];
   ArraySetAsSeries(main,true);
   ArraySetAsSeries(signal,true);
   int start_pos=0,count=6;
   if(!iGetArray(handle_iMACD,MAIN_LINE,start_pos,count,main) ||  !iGetArray(handle_iMACD,SIGNAL_LINE,start_pos,count,signal))
      return(false);
   int size_need_position=ArraySize(SPosition);
   if(size_need_position>0)
      return(true);
//---
   if(InpMACDSignalReverse!=reverse_off)
     {
      if(InpMACDSignalReverse==reverse)
        {
         //--- check buy signal
         if(m_last_deal_in_type==WRONG_VALUE || m_last_deal_in_type==DEAL_TYPE_BUY) // deal type
            if(main[m_bar_current+2]>main[m_bar_current+1] && main[m_bar_current+1]<main[m_bar_current]) // signal
              {
               //--- step
               if(m_minimum_step>0.0 && (m_last_deal_in_price>0.0 && MathAbs(m_symbol.Ask()-m_last_deal_in_price)<m_minimum_step))
                  return(true);
               //--- volume
               double lot=CalculateVolume();
               if(lot>0.0)
                 {
                  size_need_position=ArraySize(SPosition);
                  if(m_prev_bars==m_last_deal_in) // on one bar - only one deal
                     return(true);
                  ArrayResize(SPosition,size_need_position+1);
                  SPosition[size_need_position].pos_type=POSITION_TYPE_BUY;
                  SPosition[size_need_position].volume=lot;
                  if(InpPrintLog)
                     Print(__FILE__," ",__FUNCTION__,", OK: ","Signal Reverse BUY");
                  return(true);
                 }
               else
                 {
                  m_global_stop=true;
                  if(InpMail)
                     SendMail("Global stop","Signal Reverse BUY, lor 0.0");
                  if(InpNotification)
                     SendNotification("Global stop."+" Signal Reverse BUY, lor 0.0");
                  //---
                  ArrayFree(SPosition);
                  return(true);
                 }
              }
         //--- check sell signal
         if(m_last_deal_in_type==WRONG_VALUE || m_last_deal_in_type==DEAL_TYPE_SELL) // deal type
            if(main[m_bar_current+2]<main[m_bar_current+1] && main[m_bar_current+1]>main[m_bar_current]) // signal
              {
               //--- step
               if(m_minimum_step>0.0 && (m_last_deal_in_price>0.0 && MathAbs(m_symbol.Bid()-m_last_deal_in_price)<m_minimum_step))
                  return(true);
               //--- volume
               double lot=CalculateVolume();
               if(lot>0.0)
                 {
                  size_need_position=ArraySize(SPosition);
                  if(m_prev_bars==m_last_deal_in) // on one bar - only one deal
                     return(true);
                  ArrayResize(SPosition,size_need_position+1);
                  SPosition[size_need_position].pos_type=POSITION_TYPE_SELL;
                  SPosition[size_need_position].volume=lot;
                  if(InpPrintLog)
                     Print(__FILE__," ",__FUNCTION__,", OK: ","Signal Reverse SELL");
                  return(true);
                 }
               else
                 {
                  m_global_stop=true;
                  if(InpMail)
                     SendMail("Global stop","Signal Reverse SELL, lor 0.0");
                  if(InpNotification)
                     SendNotification("Global stop."+" Signal Reverse SELL, lor 0.0");
                  ArrayFree(SPosition);
                  return(true);
                 }
              }
        }
      if(InpMACDSignalReverse==reverse_zero)
        {
         //--- check buy signal
         if(m_last_deal_in_type==WRONG_VALUE || m_last_deal_in_type==DEAL_TYPE_BUY) // deal type
            if(main[m_bar_current+2]>main[m_bar_current+1] && main[m_bar_current+1]<main[m_bar_current]) // signal
               if(main[m_bar_current+2]<0.0 && main[m_bar_current+1]<0.0 && main[m_bar_current]<0.0)
                 {
                  //--- step
                  if(m_minimum_step>0.0 && (m_last_deal_in_price>0.0 && MathAbs(m_symbol.Ask()-m_last_deal_in_price)<m_minimum_step))
                     return(true);
                  //--- volume
                  double lot=CalculateVolume();
                  if(lot>0.0)
                    {
                     size_need_position=ArraySize(SPosition);
                     if(m_prev_bars==m_last_deal_in) // on one bar - only one deal
                        return(true);
                     ArrayResize(SPosition,size_need_position+1);
                     SPosition[size_need_position].pos_type=POSITION_TYPE_BUY;
                     SPosition[size_need_position].volume=lot;
                     if(InpPrintLog)
                        Print(__FILE__," ",__FUNCTION__,", OK: ","Signal Reverse zero BUY");
                     return(true);
                    }
                  else
                    {
                     m_global_stop=true;
                     if(InpMail)
                        SendMail("Global stop","Signal Reverse zero BUY, lor 0.0");
                     if(InpNotification)
                        SendNotification("Global stop."+" Signal Reverse zero BUY, lor 0.0");
                     //---
                     ArrayFree(SPosition);
                     return(true);
                    }
                 }
         //--- check sell signal
         if(m_last_deal_in_type==WRONG_VALUE || m_last_deal_in_type==DEAL_TYPE_SELL) // deal type
            if(main[m_bar_current+2]<main[m_bar_current+1] && main[m_bar_current+1]>main[m_bar_current]) // signal
               if(main[m_bar_current+2]<0.0 && main[m_bar_current+1]<0.0 && main[m_bar_current]<0.0)
                 {
                  //--- step
                  if(m_minimum_step>0.0 && (m_last_deal_in_price>0.0 && MathAbs(m_symbol.Bid()-m_last_deal_in_price)<m_minimum_step))
                     return(true);
                  //--- volume
                  double lot=CalculateVolume();
                  if(lot>0.0)
                    {
                     size_need_position=ArraySize(SPosition);
                     if(m_prev_bars==m_last_deal_in) // on one bar - only one deal
                        return(true);
                     ArrayResize(SPosition,size_need_position+1);
                     SPosition[size_need_position].pos_type=POSITION_TYPE_SELL;
                     SPosition[size_need_position].volume=lot;
                     if(InpPrintLog)
                        Print(__FILE__," ",__FUNCTION__,", OK: ","Signal Reverse zero SELL");
                     return(true);
                    }
                  else
                    {
                     m_global_stop=true;
                     if(InpMail)
                        SendMail("Global stop","Signal Reverse zero SELL, lor 0.0");
                     if(InpNotification)
                        SendNotification("Global stop."+" Signal Reverse zero SELL, lor 0.0");
                     ArrayFree(SPosition);
                     return(true);
                    }
                 }
        }
     }
//---
   if(InpMACDSignalCrossover!=crossover_off)
     {
      if(InpMACDSignalCrossover==crossover)
        {
         //--- check buy signal
         if(m_last_deal_in_type==WRONG_VALUE || m_last_deal_in_type==DEAL_TYPE_BUY) // deal type
            if(main[m_bar_current+1]<signal[m_bar_current+1] && main[m_bar_current]>signal[m_bar_current]) // signal
              {
               //--- step
               if(m_minimum_step>0.0 && (m_last_deal_in_price>0.0 && MathAbs(m_symbol.Ask()-m_last_deal_in_price)<m_minimum_step))
                  return(true);
               //--- volume
               double lot=CalculateVolume();
               if(lot>0.0)
                 {
                  size_need_position=ArraySize(SPosition);
                  if(m_prev_bars==m_last_deal_in) // on one bar - only one deal
                     return(true);
                  ArrayResize(SPosition,size_need_position+1);
                  SPosition[size_need_position].pos_type=POSITION_TYPE_BUY;
                  SPosition[size_need_position].volume=lot;
                  if(InpPrintLog)
                     Print(__FILE__," ",__FUNCTION__,", OK: ","Signal Crossover BUY");
                  return(true);
                 }
               else
                 {
                  m_global_stop=true;
                  if(InpMail)
                     SendMail("Global stop","Signal Crossover BUY, lor 0.0");
                  if(InpNotification)
                     SendNotification("Global stop."+" Signal Crossover BUY, lor 0.0");
                  ArrayFree(SPosition);
                  return(true);
                 }
              }
         //--- check sell signal
         if(m_last_deal_in_type==WRONG_VALUE || m_last_deal_in_type==DEAL_TYPE_SELL) // deal type
            if(main[m_bar_current+1]>signal[m_bar_current+1] && main[m_bar_current]<signal[m_bar_current]) // signal
              {
               //--- step
               if(m_minimum_step>0.0 && (m_last_deal_in_price>0.0 && MathAbs(m_symbol.Bid()-m_last_deal_in_price)<m_minimum_step))
                  return(true);
               //--- volume
               double lot=CalculateVolume();
               if(lot>0.0)
                 {
                  size_need_position=ArraySize(SPosition);
                  if(m_prev_bars==m_last_deal_in) // on one bar - only one deal
                     return(true);
                  ArrayResize(SPosition,size_need_position+1);
                  SPosition[size_need_position].pos_type=POSITION_TYPE_SELL;
                  SPosition[size_need_position].volume=lot;
                  if(InpPrintLog)
                     Print(__FILE__," ",__FUNCTION__,", OK: ","Signal Crossover SELL");
                  return(true);
                 }
               else
                 {
                  m_global_stop=true;
                  if(InpMail)
                     SendMail("Global stop","Signal Crossover SELL, lor 0.0");
                  if(InpNotification)
                     SendNotification("Global stop."+" Signal Crossover SELL, lor 0.0");
                  ArrayFree(SPosition);
                  return(true);
                 }
              }
        }
      if(InpMACDSignalCrossover==crossover_zero)
        {
         //--- check buy signal
         if(m_last_deal_in_type==WRONG_VALUE || m_last_deal_in_type==DEAL_TYPE_BUY) // deal type
            if(main[m_bar_current+1]<signal[m_bar_current+1] && main[m_bar_current]>signal[m_bar_current]) // signal
               if(main[m_bar_current+1]<0.0 && signal[m_bar_current+1]<0.0 && main[m_bar_current]<0.0 && signal[m_bar_current]<0.0)
                 {
                  //--- step
                  if(m_minimum_step>0.0 && (m_last_deal_in_price>0.0 && MathAbs(m_symbol.Ask()-m_last_deal_in_price)<m_minimum_step))
                     return(true);
                  //--- volume
                  double lot=CalculateVolume();
                  if(lot>0.0)
                    {
                     size_need_position=ArraySize(SPosition);
                     if(m_prev_bars==m_last_deal_in) // on one bar - only one deal
                        return(true);
                     ArrayResize(SPosition,size_need_position+1);
                     SPosition[size_need_position].pos_type=POSITION_TYPE_BUY;
                     SPosition[size_need_position].volume=lot;
                     if(InpPrintLog)
                        Print(__FILE__," ",__FUNCTION__,", OK: ","Signal Crossover zero BUY");
                     return(true);
                    }
                  else
                    {
                     m_global_stop=true;
                     if(InpMail)
                        SendMail("Global stop","Signal Crossover zero BUY, lor 0.0");
                     if(InpNotification)
                        SendNotification("Global stop."+" Signal Crossover zero BUY, lor 0.0");
                     ArrayFree(SPosition);
                     return(true);
                    }
                 }
         //--- check sell signal
         if(m_last_deal_in_type==WRONG_VALUE || m_last_deal_in_type==DEAL_TYPE_SELL) // deal type
            if(main[m_bar_current+1]>signal[m_bar_current+1] && main[m_bar_current]<signal[m_bar_current]) // signal
               if(main[m_bar_current+1]>0.0 && signal[m_bar_current+1]>0.0 && main[m_bar_current]>0.0 && signal[m_bar_current]>0.0)
                 {
                  //--- step
                  if(m_minimum_step>0.0 && (m_last_deal_in_price>0.0 && MathAbs(m_symbol.Bid()-m_last_deal_in_price)<m_minimum_step))
                     return(true);
                  //--- volume
                  double lot=CalculateVolume();
                  if(lot>0.0)
                    {
                     size_need_position=ArraySize(SPosition);
                     if(m_prev_bars==m_last_deal_in) // on one bar - only one deal
                        return(true);
                     ArrayResize(SPosition,size_need_position+1);
                     SPosition[size_need_position].pos_type=POSITION_TYPE_SELL;
                     SPosition[size_need_position].volume=lot;
                     if(InpPrintLog)
                        Print(__FILE__," ",__FUNCTION__,", OK: ","Signal Crossover zero SELL");
                     return(true);
                    }
                  else
                    {
                     m_global_stop=true;
                     if(InpMail)
                        SendMail("Global stop","Signal Crossover zero SELL, lor 0.0");
                     if(InpNotification)
                        SendNotification("Global stop."+" Signal Crossover zero SELL, lor 0.0");
                     ArrayFree(SPosition);
                     return(true);
                    }
                 }
        }
     }
//---
   if(InpMACDSignalCrossing!=crossing_off)
     {
      //--- check buy signal
      if(m_last_deal_in_type==WRONG_VALUE || m_last_deal_in_type==DEAL_TYPE_BUY) // deal type
         if(main[m_bar_current+1]<0.0 && main[m_bar_current]>0.0) // signal
           {
            //--- step
            if(m_minimum_step>0.0 && (m_last_deal_in_price>0.0 && MathAbs(m_symbol.Ask()-m_last_deal_in_price)<m_minimum_step))
               return(true);
            //--- volume
            double lot=CalculateVolume();
            if(lot>0.0)
              {
               size_need_position=ArraySize(SPosition);
               if(m_prev_bars==m_last_deal_in) // on one bar - only one deal
                  return(true);
               ArrayResize(SPosition,size_need_position+1);
               SPosition[size_need_position].pos_type=POSITION_TYPE_BUY;
               SPosition[size_need_position].volume=lot;
               if(InpPrintLog)
                  Print(__FILE__," ",__FUNCTION__,", OK: ","Signal Crossing BUY");
               return(true);
              }
            else
              {
               m_global_stop=true;
               if(InpMail)
                  SendMail("Global stop","Signal Crossing BUY, lor 0.0");
               if(InpNotification)
                  SendNotification("Global stop."+" Signal Crossing BUY, lor 0.0");
               ArrayFree(SPosition);
               return(true);
              }
           }
      //--- check sell signal
      if(m_last_deal_in_type==WRONG_VALUE || m_last_deal_in_type==DEAL_TYPE_SELL) // deal type
         if(main[m_bar_current+1]>0.0 && main[m_bar_current]<0.0) // signal
           {
            //--- step
            if(m_minimum_step>0.0 && (m_last_deal_in_price>0.0 && MathAbs(m_symbol.Bid()-m_last_deal_in_price)<m_minimum_step))
               return(true);
            //--- volume
            double lot=CalculateVolume();
            if(lot>0.0)
              {
               size_need_position=ArraySize(SPosition);
               if(m_prev_bars==m_last_deal_in) // on one bar - only one deal
                  return(true);
               ArrayResize(SPosition,size_need_position+1);
               SPosition[size_need_position].pos_type=POSITION_TYPE_SELL;
               SPosition[size_need_position].volume=lot;
               if(InpPrintLog)
                  Print(__FILE__," ",__FUNCTION__,", OK: ","Signal Crossing SELL");
               return(true);
              }
            else
              {
               m_global_stop=true;
               if(InpMail)
                  SendMail("Global stop","Signal Crossing SELL, lor 0.0");
               if(InpNotification)
                  SendNotification("Global stop."+" Signal Crossing SELL, lor 0.0");
               ArrayFree(SPosition);
               return(true);
              }
           }
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Is position exists                                               |
//+------------------------------------------------------------------+
bool IsPositionExists(void)
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
            return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions(void)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(!m_trade.PositionClose(m_position.Ticket())) // close a position by the specified m_symbol
                  if(InpPrintLog)
                     Print(__FILE__," ",__FUNCTION__,", ERROR: ","BUY PositionClose ",m_position.Ticket(),", ",m_trade.ResultRetcodeDescription());
              }
            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               if(!m_trade.PositionClose(m_position.Ticket())) // close a position by the specified m_symbol
                  if(InpPrintLog)
                     Print(__FILE__," ",__FUNCTION__,", ERROR: ","SELL PositionClose ",m_position.Ticket(),", ",m_trade.ResultRetcodeDescription());
              }
           }
  }
//+------------------------------------------------------------------+
//| Calculate Volume                                                 |
//+------------------------------------------------------------------+
double CalculateVolume(void)
  {
   double volume=0.0;
   if(m_last_deal_in_volume==0.0)
      volume=InpLots;
   else
      volume=LotCheck(m_last_deal_in_volume*InpPositionIncreaseRatio,m_symbol);
//--- check Maximum position volume
   if(volume>=InpMaximumPositionVolume)
      return(0.0);
//--- check The maximum total volume of positions
   if(CalculateTotalVolume()>=InpMaximumTotalVolume+volume)
      return(0.0);
//---
   return(volume);
  }
//+------------------------------------------------------------------+
//| Calculate Total Volume                                           |
//+------------------------------------------------------------------+
double CalculateTotalVolume(void)
  {
   double total_volume=0.0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
            total_volume+=m_position.Volume();
//---
   return(total_volume);
  }
//+------------------------------------------------------------------+
//| Profit all positions                                             |
//+------------------------------------------------------------------+
double ProfitAllPositions(void)
  {
   double profit=0.0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
            profit+=m_position.Commission()+m_position.Swap()+m_position.Profit();
//---
   return(profit);
  }
//+------------------------------------------------------------------+
