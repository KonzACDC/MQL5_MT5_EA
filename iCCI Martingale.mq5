//+------------------------------------------------------------------+
//|                                              iCCI Martingale.mq5 |
//|                         Copyright © 2018-2021, Vladimir Karputov |
//|                      https://www.mql5.com/en/users/barabashkakvn |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018-2021, Vladimir Karputov"
#property link      "https://www.mql5.com/en/users/barabashkakvn"
#property version   "1.004"
/*
   barabashkakvn Trading engine 4.004
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
//| Enum Step                                                        |
//+------------------------------------------------------------------+
enum ENUM_STEP
  {
   loss=-1,    // ... lossing
   profit=1,   // ... profitable
  };
//--- input parameters
input group             "Trading settings"
input ENUM_TIMEFRAMES      InpWorkingPeriod        = PERIOD_CURRENT; // Working timeframe
input uint                 InpStopLoss             = 200;            // Stop Loss
input uint                 InpTakeProfit           = 500;            // Take Profit
input uint                 InpTrailingStop         = 50;             // Trailing Stop (min distance from price to Stop Loss)
input uint                 InpTrailingStep         = 150;            // Trailing Step
input group             "Position size management (lot calculation)"
input double               InpLots                 = 0.1;            // Lots
input group             "CCI"
input int                  Inp_CCI_ma_period       = 27;             // CCI: averaging period
input ENUM_APPLIED_PRICE   Inp_CCI_applied_price   = PRICE_TYPICAL;  // CCI: type of price
input group             "Time control"
input bool                 InpTimeControl          = false;          // Use time control
input uchar                InpStartHour            = 10;             // Start Hour
input uchar                InpStartMinute          = 01;             // Start Minute
input uchar                InpEndHour              = 15;             // End Hour
input uchar                InpEndMinute            = 02;             // End Minute
input group             "Martingale"
input bool                 InpMartin               = true;           // Use martingale
input double               InpMartinCoeff          = 3.0;            // Martingale coefficient
input int                  InpMartinOrdinalNumber  = 1;              // Ordinal number of the losing trade
input int                  InpMartinMaxMultiplications=3;            // Maximum number of multiplications
input group             "Step by step"
input bool                 InpStep                 = false;          // Use step by step
input double               InpStepLots             = 0.1;            // Step lots
input double               InpStepLotsMax          = 1.5;            // Maximum lots
input ENUM_STEP            InpStepProfit           = loss;           // Use step afte ...
input group             "Day limits in money deposit"
input double               InpMaxDailyLoss         = 100;            // Maximum daily loss ('0' -> OFF)
input double               InpDailyProfitTarget    = 200;            // Daily profit target ('0' -> OFF)
input group             "Additional features"
input bool                 InpPrintLog             = true;           // Print log
input uchar                InpFreezeCoefficient    = 1;              // Coefficient (if Freeze==0 Or StopsLevels==0)
input ulong                InpDeviation            = 10;             // Deviation, in Points (1.00045-1.00055=10 points)
input ulong                InpMagic                = 324399170;      // Magic number
//---
double   m_stop_loss                = 0.0;      // Stop Loss                  -> double
double   m_take_profit              = 0.0;      // Take Profit                -> double
double   m_trailing_stop            = 0.0;      // Trailing Stop              -> double
double   m_trailing_step            = 0.0;      // Trailing Step              -> double

int      handle_iCCI;                           // variable for storing the handle of the iCCI indicator

bool     m_need_close_all           = false;    // close all positions
datetime m_day_stop                 = 0;        // "0" -> D'1970.01.01 00:00';
double   m_lots                     = 0.0;
int      m_martin                   = 0;
int      m_loss                     = 0;
int      m_profit                   = 0;

bool     m_init_error               = false;    // error on InInit
//--- the tactic is this: for positions we strictly monitor the result, ***
//+------------------------------------------------------------------+
//| Structure Positions                                              |
//+------------------------------------------------------------------+
struct STRUCT_POSITION
  {
   ENUM_POSITION_TYPE pos_type;              // position type
   bool              waiting_transaction;    // waiting transaction, "true" -> it's forbidden to trade, we expect a transaction
   ulong             waiting_order_ticket;   // waiting order ticket, ticket of the expected order
   bool              transaction_confirmed;  // transaction confirmed, "true" -> transaction confirmed
   //--- Constructor
                     STRUCT_POSITION()
     {
      pos_type                   = WRONG_VALUE;
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
   m_stop_loss                = 0.0;      // Stop Loss                  -> double
   m_take_profit              = 0.0;      // Take Profit                -> double
   m_trailing_stop            = 0.0;      // Trailing Stop              -> double
   m_trailing_step            = 0.0;      // Trailing Step              -> double
   m_need_close_all           = false;    // close all positions
   m_day_stop                 = 0;        // "0" -> D'1970.01.01 00:00';
   m_lots                     = 0.0;
   m_martin                   = 0;
   m_loss                     = 0;
   m_profit                   = 0;
   m_init_error               = false;    // error on InInit
//---
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      string err_text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                      "Трейлинг невозможен: параметр \"Trailing Step\" равен нулю!":
                      "Trailing is not possible: parameter \"Trailing Step\" is zero!";
      if(MQLInfoInteger(MQL_TESTER)) // when testing, we will only output to the log about incorrect input parameters
         Print(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
      else // if the Expert Advisor is run on the chart, tell the user about the error
         Alert(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
      //---
      m_init_error=true;
      return(INIT_SUCCEEDED);
     }
   if(InpMartin && InpStep)
     {
      string err_text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                      "Торговля запрещена: \"Use martingale\" = "+((InpMartin)?"true":"false")+
                      ", \"Use step by step\" = "+((InpStep)?"true":"false")+"!":
                      "Trade is prohibited: \"Use martingale\" = "+((InpMartin)?"true":"false")+
                      ", \"Use step by step\" = "+((InpStep)?"true":"false")+"!";
      Alert(__FILE__," ",__FUNCTION__,", ERROR: ",err_text);
      //---
      m_init_error=true;
      return(INIT_SUCCEEDED);
     }
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
   m_stop_loss                = InpStopLoss                 * m_symbol.Point();
   m_take_profit              = InpTakeProfit               * m_symbol.Point();
   m_trailing_stop            = InpTrailingStop             * m_symbol.Point();
   m_trailing_step            = InpTrailingStep             * m_symbol.Point();
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
   if(InpStep)
     {
      err_text="";
      if(!CheckVolumeValue(InpStepLots,err_text))
        {
         if(MQLInfoInteger(MQL_TESTER)) // when testing, we will only output to the log about incorrect input parameters
            Print(__FILE__," ",__FUNCTION__,", ERROR 'Step lots': ",err_text);
         else // if the Expert Advisor is run on the chart, tell the user about the error
            Alert(__FILE__," ",__FUNCTION__,", ERROR 'Step lots': ",err_text);
         //---
         m_init_error=true;
         return(INIT_SUCCEEDED);
        }
      //---
      err_text="";
      if(!CheckVolumeValue(InpStepLotsMax,err_text))
        {
         if(MQLInfoInteger(MQL_TESTER)) // when testing, we will only output to the log about incorrect input parameters
            Print(__FILE__," ",__FUNCTION__,", ERROR 'Maximum lots': ",err_text);
         else // if the Expert Advisor is run on the chart, tell the user about the error
            Alert(__FILE__," ",__FUNCTION__,", ERROR 'Maximum lots': ",err_text);
         //---
         m_init_error=true;
         return(INIT_SUCCEEDED);
        }
     }
//--- create handle of the indicator iCCI
   handle_iCCI=iCCI(m_symbol.Name(),InpWorkingPeriod,Inp_CCI_ma_period,Inp_CCI_applied_price);
//--- if the handle is not created
   if(handle_iCCI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iCCI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(InpWorkingPeriod),
                  GetLastError());
      //--- the indicator is stopped early
      m_init_error=true;
      return(INIT_SUCCEEDED);
     }
//---
   m_lots=InpLots;
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
         ArrayFree(SPosition);
        }
     }
//---
   if(m_day_stop==iTime(m_symbol.Name(),PERIOD_D1,0))
      return;
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
   if(IsPositionExists())
     {
      //--- trailing at every tick
      Trailing();
     }
   else
     {
      //--- search for trading signals at every tick
      SearchTradingSignals();
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
            if(m_deal.Entry()==DEAL_ENTRY_OUT)
              {
               //--- Day limits in money deposit
               double profit_day=ProfitForPeriod();
               if(InpMaxDailyLoss!=0.0)
                 {
                  if(profit_day<=-(MathAbs(InpMaxDailyLoss)))
                    {
                     m_need_close_all=true;
                     m_day_stop=iTime(m_symbol.Name(),PERIOD_D1,0);
                     return;
                    }
                 }
               if(InpDailyProfitTarget!=0.0)
                 {
                  if(profit_day>=(MathAbs(InpDailyProfitTarget)))
                    {
                     m_need_close_all=true;
                     m_day_stop=iTime(m_symbol.Name(),PERIOD_D1,0);
                     return;
                    }
                 }
               //--- Martingale, Step by step
               if(!InpMartin && !InpStep)
                 {
                  m_lots=InpLots;
                  return;
                 }
               //---
               double deal_profit=m_deal.Commission()+m_deal.Swap()+m_deal.Profit();
               if(deal_profit<0.0)
                  m_loss++;
               else
                  m_profit++;
               //---
               if(InpMartin)
                 {
                  /*
                  InpMartinCoeff                = 1.51;           // Martingale coefficient
                  InpMartinOrdinalNumber        = 1;              // Ordinal number of the losing trade
                  InpMartinMaxMultiplications   = 3;              // Maximum number of multiplications
                  */
                  if(deal_profit<0.0)
                    {
                     if(m_martin<=InpMartinMaxMultiplications)
                        if(m_loss>=InpMartinOrdinalNumber)
                          {
                           double lot_check=LotCheck(m_lots*InpMartinCoeff,m_symbol);
                           if(lot_check==0)
                              m_lots=InpLots;  // protection (just in case)
                           else
                              m_lots=lot_check;
                           m_martin++;
                           return;
                          }
                    }
                  else
                    {
                     m_lots   = InpLots;        // start lot
                     m_martin = 0;              // Maximum number of multiplications == "0"
                     m_loss   = 0;              // count loss == "0"
                     m_profit = 0;              // count profit == "0" (so that the counter does not overflow)
                    }
                 }
               if(InpStep)
                 {
                  /*
                  InpStepLots                   = 0.1;            // Step lots
                  InpStepLotsMax                = 1.5;            // Maximum lots
                  InpStepProfit                 = loss;           // Use step afte ...
                  */
                  if(InpStepProfit==loss)
                    {
                     if(deal_profit<0)
                       {
                        double lot_check=LotCheck(m_lots+InpStepLots,m_symbol);
                        if(lot_check==0.0)
                           m_lots=InpLots;     // protection (just in case)
                        if(lot_check<=InpStepLotsMax)
                           m_lots=InpLots;
                       }
                     else
                        m_lots=InpLots;
                    }
                  else // InpStepProfit==profit
                    {
                     if(deal_profit>=0)
                       {
                        double lot_check=LotCheck(m_lots+InpStepLots,m_symbol);
                        if(lot_check==0.0)
                           m_lots=InpLots;     // protection (just in case)
                        if(lot_check<=InpStepLotsMax)
                           m_lots=InpLots;
                       }
                     else
                        m_lots=InpLots;
                    }
                  //---
                  m_loss      = 0;              // count loss == "0" (so that the counter does not overflow)
                  m_profit    = 0;              // count profit == "0" (so that the counter does not overflow)
                 }
              }
            //---
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
//| Check Freeze and Stops levels                                    |
//+------------------------------------------------------------------+
void FreezeStopsLevels(double &freeze,double &stops)
  {
//--- check Freeze and Stops levels
   /*
   SYMBOL_TRADE_FREEZE_LEVEL shows the distance of freezing the trade operations
      for pending orders and open positions in points
   ------------------------|--------------------|--------------------------------------------
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask               |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid               |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order         |  Bid               |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid               |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask               |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
   ------------------------------------------------------------------------------------------

   SYMBOL_TRADE_STOPS_LEVEL determines the number of points for minimum indentation of the
      StopLoss and TakeProfit levels from the current closing price of the open position
   ------------------------------------------------|------------------------------------------
   Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|------------------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid                        |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
   ------------------------------------------------------------------------------------------
   */
   double coeff=(double)InpFreezeCoefficient;
   if(!RefreshRates() || !m_symbol.Refresh())
      return;
//--- FreezeLevel -> for pending order and modification
   double freeze_level=m_symbol.FreezeLevel()*m_symbol.Point();
   if(freeze_level==0.0)
      if(InpFreezeCoefficient>0)
         freeze_level=(m_symbol.Ask()-m_symbol.Bid())*coeff;
//--- StopsLevel -> for TakeProfit and StopLoss
   double stop_level=m_symbol.StopsLevel()*m_symbol.Point();
   if(stop_level==0.0)
      if(InpFreezeCoefficient>0)
         stop_level=(m_symbol.Ask()-m_symbol.Bid())*coeff;
//---
   freeze=freeze_level;
   stops=stop_level;
//---
   return;
  }
//+------------------------------------------------------------------+
//| Open position                                                    |
//+------------------------------------------------------------------+
void OpenPosition(const int index)
  {
   double freeze=0.0,stops=0.0;
   FreezeStopsLevels(freeze,stops);
   double max_levels=(freeze>stops)?freeze:stops;
   /*
   SYMBOL_TRADE_STOPS_LEVEL determines the number of points for minimum indentation of the
      StopLoss and TakeProfit levels from the current closing price of the open position
   ------------------------------------------------|------------------------------------------
   Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|------------------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid                        |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
   ------------------------------------------------------------------------------------------
   */
//--- buy
   if(SPosition[index].pos_type==POSITION_TYPE_BUY)
     {
      double sl=(m_stop_loss==0.0)?0.0:m_symbol.Ask()-m_stop_loss;
      if(sl>0.0)
         if(m_symbol.Bid()-sl<max_levels)
            sl=m_symbol.Bid()-max_levels;
      double tp=(m_take_profit==0.0)?0.0:m_symbol.Ask()+m_take_profit;
      if(tp>0.0)
         if(tp-m_symbol.Ask()<max_levels)
            tp=m_symbol.Ask()+max_levels;
      OpenBuy(index,sl,tp);
      return;
     }
//--- sell
   if(SPosition[index].pos_type==POSITION_TYPE_SELL)
     {
      double sl=(m_stop_loss==0.0)?0.0:m_symbol.Bid()+m_stop_loss;
      if(sl>0.0)
         if(sl-m_symbol.Ask()<max_levels)
            sl=m_symbol.Ask()+max_levels;
      double tp=(m_take_profit==0.0)?0.0:m_symbol.Bid()-m_take_profit;
      if(tp>0.0)
         if(m_symbol.Bid()-tp<max_levels)
            tp=m_symbol.Bid()-max_levels;
      OpenSell(index,sl,tp);
      return;
     }
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(const int index,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
   double long_lot=m_lots;
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
void OpenSell(const int index,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
   double short_lot=m_lots;
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
//| Trailing                                                         |
//|   InpTrailingStop: min distance from price to Stop Loss          |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(InpTrailingStop==0)
      return;
   double freeze=0.0,stops=0.0;
   FreezeStopsLevels(freeze,stops);
   double max_levels=(freeze>stops)?freeze:stops;
   /*
   SYMBOL_TRADE_FREEZE_LEVEL shows the distance of freezing the trade operations
      for pending orders and open positions in points
   ------------------------|--------------------|--------------------------------------------
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask               |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid               |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order         |  Bid               |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid               |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask               |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
   ------------------------------------------------------------------------------------------
   */
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
           {
            double price_current = m_position.PriceCurrent();
            double price_open    = m_position.PriceOpen();
            double stop_loss     = m_position.StopLoss();
            double take_profit   = m_position.TakeProfit();
            double ask           = m_symbol.Ask();
            double bid           = m_symbol.Bid();
            //---
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(price_current-price_open>m_trailing_stop+m_trailing_step)
                  if(stop_loss<price_current-(m_trailing_stop+m_trailing_step))
                     if(m_trailing_stop>=max_levels && (take_profit-bid>=max_levels || take_profit==0.0))
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                                                   m_symbol.NormalizePrice(price_current-m_trailing_stop),
                                                   take_profit))
                           if(InpPrintLog)
                              Print(__FILE__," ",__FUNCTION__,", ERROR: ","Modify BUY ",m_position.Ticket(),
                                    " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                    ", description of result: ",m_trade.ResultRetcodeDescription());
                        if(InpPrintLog)
                          {
                           RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                        continue;
                       }
              }
            else
              {
               if(price_open-price_current>m_trailing_stop+m_trailing_step)
                  if((stop_loss>(price_current+(m_trailing_stop+m_trailing_step))) || (stop_loss==0))
                     if(m_trailing_stop>=max_levels && ask-take_profit>=max_levels)
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                                                   m_symbol.NormalizePrice(price_current+m_trailing_stop),
                                                   take_profit))
                           if(InpPrintLog)
                              Print(__FILE__," ",__FUNCTION__,", ERROR: ","Modify SELL ",m_position.Ticket(),
                                    " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                    ", description of result: ",m_trade.ResultRetcodeDescription());
                        if(InpPrintLog)
                          {
                           RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                       }
              }
           }
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultModify(CTrade &trade,CSymbolInfo &symbol,CPositionInfo &position)
  {
   Print("File: ",__FILE__,", symbol: ",symbol.Name());
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result as a string: "+trade.ResultRetcodeDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("Order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
   Print("Freeze Level: "+DoubleToString(symbol.FreezeLevel(),0),", Stops Level: "+DoubleToString(symbol.StopsLevel(),0));
   Print("Price of position opening: "+DoubleToString(position.PriceOpen(),symbol.Digits()));
   Print("Price of position's Stop Loss: "+DoubleToString(position.StopLoss(),symbol.Digits()));
   Print("Price of position's Take Profit: "+DoubleToString(position.TakeProfit(),symbol.Digits()));
   Print("Current price by position: "+DoubleToString(position.PriceCurrent(),symbol.Digits()));
  }
//+------------------------------------------------------------------+
//| Close positions                                                  |
//+------------------------------------------------------------------+
void ClosePositions(const ENUM_POSITION_TYPE pos_type)
  {
   double freeze=0.0,stops=0.0;
   FreezeStopsLevels(freeze,stops);
   /*
   SYMBOL_TRADE_FREEZE_LEVEL shows the distance of freezing the trade operations
      for pending orders and open positions in points
   ------------------------|--------------------|--------------------------------------------
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask               |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid               |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order         |  Bid               |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid               |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask               |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
   ------------------------------------------------------------------------------------------
   */
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
            if(m_position.PositionType()==pos_type)
              {
               if(m_position.PositionType()==POSITION_TYPE_BUY)
                 {
                  bool take_profit_level=((m_position.TakeProfit()!=0.0 && m_position.TakeProfit()-m_position.PriceCurrent()>=freeze) || m_position.TakeProfit()==0.0);
                  bool stop_loss_level=((m_position.StopLoss()!=0.0 && m_position.PriceCurrent()-m_position.StopLoss()>=freeze) || m_position.StopLoss()==0.0);
                  if(take_profit_level && stop_loss_level)
                     if(!m_trade.PositionClose(m_position.Ticket())) // close a position by the specified m_symbol
                        if(InpPrintLog)
                           Print(__FILE__," ",__FUNCTION__,", ERROR: ","BUY PositionClose ",m_position.Ticket(),", ",m_trade.ResultRetcodeDescription());
                 }
               if(m_position.PositionType()==POSITION_TYPE_SELL)
                 {
                  bool take_profit_level=((m_position.TakeProfit()!=0.0 && m_position.PriceCurrent()-m_position.TakeProfit()>=freeze) || m_position.TakeProfit()==0.0);
                  bool stop_loss_level=((m_position.StopLoss()!=0.0 && m_position.StopLoss()-m_position.PriceCurrent()>=freeze) || m_position.StopLoss()==0.0);
                  if(take_profit_level && stop_loss_level)
                     if(!m_trade.PositionClose(m_position.Ticket())) // close a position by the specified m_symbol
                        if(InpPrintLog)
                           Print(__FILE__," ",__FUNCTION__,", ERROR: ","SELL PositionClose ",m_position.Ticket(),", ",m_trade.ResultRetcodeDescription());
                 }
              }
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
   if(!TimeControlHourMinute())
      return(true);
//---
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(),STimeCurrent);
   if(STimeCurrent.sec<40)
      return(true);
//---
   double cci[];
   MqlRates rates[];
   ArraySetAsSeries(cci,true);
   ArraySetAsSeries(rates,true);
   int start_pos=0,count=6;
   if(!iGetArray(handle_iCCI,0,start_pos,count,cci) || CopyRates(m_symbol.Name(),InpWorkingPeriod,start_pos,count,rates)!=count)
      return(false);
   int size_need_position=ArraySize(SPosition);
   if(size_need_position>0)
      return(true);
//--- BUY Signal
   /* BUY
   #2       #1       #0
                     close
   open              |   |
   |||||             |   |
   |||||    open     open
   close    |||||
            |||||
            close
   */
   if(cci[1]<5.0 && cci[2]<cci[3] && cci[1]<cci[2] && cci[0]>cci[1] &&
      rates[2].open>rates[2].close && rates[1].open>rates[1].close &&
      rates[0].open<rates[0].close && rates[1].open<rates[0].close)
     {
      ArrayResize(SPosition,size_need_position+1);
      SPosition[size_need_position].pos_type=POSITION_TYPE_BUY;
      if(InpPrintLog)
         Print(__FILE__," ",__FUNCTION__,", OK: ","Signal BUY");
      return(true);
     }
//--- SELL Signal
   /* SELL
   #2       #1       #0

            close
            |   |    open
   close    |   |    |||||
   |   |    open     |||||
   |   |             close
   open
   */
   if(cci[1]>-5 && cci[2]>cci[3] && cci[1]>cci[2] && cci[0]<cci[1] &&
      rates[2].open<rates[2].close && rates[1].open<rates[1].close  &&
      rates[0].open>rates[0].close && rates[1].open>rates[0].close)
     {
      ArrayResize(SPosition,size_need_position+1);
      SPosition[size_need_position].pos_type=POSITION_TYPE_SELL;
      if(InpPrintLog)
         Print(__FILE__," ",__FUNCTION__,", OK: ","Signal SELL");
      return(true);
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
   double freeze=0.0,stops=0.0;
   FreezeStopsLevels(freeze,stops);
   /*
   SYMBOL_TRADE_FREEZE_LEVEL shows the distance of freezing the trade operations
      for pending orders and open positions in points
   ------------------------|--------------------|--------------------------------------------
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask               |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid               |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order         |  Bid               |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid               |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask               |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
   ------------------------------------------------------------------------------------------
   */
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               bool take_profit_level=(m_position.TakeProfit()!=0.0 && m_position.TakeProfit()-m_position.PriceCurrent()>=freeze) || m_position.TakeProfit()==0.0;
               bool stop_loss_level=(m_position.StopLoss()!=0.0 && m_position.PriceCurrent()-m_position.StopLoss()>=freeze) || m_position.StopLoss()==0.0;
               if(take_profit_level && stop_loss_level)
                  if(!m_trade.PositionClose(m_position.Ticket())) // close a position by the specified m_symbol
                     if(InpPrintLog)
                        Print(__FILE__," ",__FUNCTION__,", ERROR: ","BUY PositionClose ",m_position.Ticket(),", ",m_trade.ResultRetcodeDescription());
              }
            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               bool take_profit_level=(m_position.TakeProfit()!=0.0 && m_position.PriceCurrent()-m_position.TakeProfit()>=freeze) || m_position.TakeProfit()==0.0;
               bool stop_loss_level=(m_position.StopLoss()!=0.0 && m_position.StopLoss()-m_position.PriceCurrent()>=freeze) || m_position.StopLoss()==0.0;
               if(take_profit_level && stop_loss_level)
                  if(!m_trade.PositionClose(m_position.Ticket())) // close a position by the specified m_symbol
                     if(InpPrintLog)
                        Print(__FILE__," ",__FUNCTION__,", ERROR: ","SELL PositionClose ",m_position.Ticket(),", ",m_trade.ResultRetcodeDescription());
              }
           }
  }
//+------------------------------------------------------------------+
//| TimeControl                                                      |
//+------------------------------------------------------------------+
bool TimeControlHourMinute(void)
  {
   if(!InpTimeControl)
      return(true);
   MqlDateTime STimeCurrent;
   datetime time_current=TimeCurrent();
   if(time_current==D'1970.01.01 00:00')
      return(false);
   TimeToStruct(time_current,STimeCurrent);
   if((InpStartHour*60*60+InpStartMinute*60)<(InpEndHour*60*60+InpEndMinute*60)) // intraday time interval
     {
      /*
      Example:
      input uchar    InpStartHour      = 5;        // Start hour
      input uchar    InpEndHour        = 10;       // End hour
      0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
      _  _  _  _  _  +  +  +  +  +  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  +  +  +  +  +  _  _  _  _  _  _
      */
      if((STimeCurrent.hour*60*60+STimeCurrent.min*60>=InpStartHour*60*60+InpStartMinute*60) &&
         (STimeCurrent.hour*60*60+STimeCurrent.min*60<InpEndHour*60*60+InpEndMinute*60))
         return(true);
     }
   else
      if((InpStartHour*60*60+InpStartMinute*60)>(InpEndHour*60*60+InpEndMinute*60)) // time interval with the transition in a day
        {
         /*
         Example:
         input uchar    InpStartHour      = 10;       // Start hour
         input uchar    InpEndHour        = 5;        // End hour
         0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
         _  _  _  _  _  _  _  _  _  _  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  _  _  _  _  _  +  +  +  +  +  +
         */
         if(STimeCurrent.hour*60*60+STimeCurrent.min*60>=InpStartHour*60*60+InpStartMinute*60 ||
            STimeCurrent.hour*60*60+STimeCurrent.min*60<InpEndHour*60*60+InpEndMinute*60)
            return(true);
        }
      else
         return(false);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Profit for the period                                            |
//+------------------------------------------------------------------+
double ProfitForPeriod(void)
  {
   double profit=0.0;
//--- request trade history
   datetime time_current      = TimeCurrent();
   MqlDateTime STimeCurrent;
   if(!TimeToStruct(time_current,STimeCurrent))
      return(0.0);
   STimeCurrent.hour=0;
   STimeCurrent.min=0;
   STimeCurrent.sec=0;
//--- HistorySelect
   datetime from_date         = StructToTime(STimeCurrent);
   datetime to_date           = from_date+86400;
   HistorySelect(from_date,to_date);
   int total_deals            = HistoryDealsTotal();
   ulong ticket_history_deal  = 0;
   if(total_deals>0)
     {
      //--- for all deals
      for(int i=total_deals-1; i>=0; i--)
        {
         //--- try to get deals ticket_history_deal
         if((ticket_history_deal=HistoryDealGetTicket(i))>0)
           {
            long     deal_type         = HistoryDealGetInteger(ticket_history_deal,DEAL_TYPE);
            if(deal_type==DEAL_TYPE_BUY || deal_type==DEAL_TYPE_SELL)
              {
               long     deal_entry        = HistoryDealGetInteger(ticket_history_deal,DEAL_ENTRY);
               if(deal_entry==DEAL_ENTRY_OUT)
                 {
                  long     deal_magic        = HistoryDealGetInteger(ticket_history_deal,DEAL_MAGIC);
                  double   deal_commission   = HistoryDealGetDouble(ticket_history_deal,DEAL_COMMISSION);
                  double   deal_swap         = HistoryDealGetDouble(ticket_history_deal,DEAL_SWAP);
                  double   deal_profit       = HistoryDealGetDouble(ticket_history_deal,DEAL_PROFIT);
                  string   deal_symbol       = HistoryDealGetString(ticket_history_deal,DEAL_SYMBOL);
                  //---
                  if(deal_symbol==m_symbol.Name() && deal_magic==InpMagic)
                     profit+=deal_commission+deal_swap+deal_profit;
                 }
              }
           }
        }
     }
//---
   return(profit);
  }
//+------------------------------------------------------------------+
