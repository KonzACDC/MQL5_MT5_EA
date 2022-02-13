//+------------------------------------------------------------------+
//|   Dealers Trade v 7.91 ZeroLag MACD(barabashkakvn's edition).mq5 |
//|                                         Copyright © 2006, Alex_N |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Alex_N"
#property link "asd-01@bk.ru"
#property version   "1.001"
#property description "Recommended timeframes: H4, D1"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CMoneyFixedMargin m_money;
//--- input parameters
input ushort   TradeSignal                = 1;     // 1:ZerolagMACD 2:ichimoku 3 Zero+ichi 4BB+ADX 
input bool     PerceptronOnOFF            = false; // true:enable perceptron
input double   InpLots                    = 0.1;   // Lots (if <= "0" -> use "Risk") 
input ushort   InpStopLoss                = 0;     // Stop Loss ("0" - the parameter is off) (in pips) 
input ushort   InpTakeProfit              = 50;    // Take Profit ("0" - the parameter is off) (in pips) 
input ushort   InpTrailingStop            = 0;     // Trailing Stop ("0" - the parameter is off) (in pips)  
input ushort   InpTrailingStep            = 5;     // Trailing Step (min value == 1)(in pips)
input double   Risk                       = 5;     // Risk in percent for a deal from a free margin
input int      InpMaxPositions            = 5;     // Max open positions
input ushort   InpIntervalPositions       = 15;    // Interval between positions
input double   InpCoeffIntervalPositions  = 1.2;   // Coefficient interval between positions
input double   InpCoeffTakeProfit         = 1.2;   // Coefficient Take profit
input double   InpSecureProfit            = 300;   // Min profit. Close max profit position
input bool     InpAccountProtection       = true;  // Account protection. If "true" -> close max profit position
input uchar    InpPosProtect              = 3;     // Number of open items if "Account protection" = "true"
input bool     InpReverseCondition        = false; // Reverse condition
input int      MACD_fast_ema_period       = 14;    // "ZeroLag MACD": fast ema period
input int      MACD_slow_ema_period       = 26;    // "ZeroLag MACD": slow ema period
input int      MACD_signal_period         = 9;     // "ZeroLag MACD": period for their difference averaging 
//ichimoku
input int                  Inp_Ichimoku_tenkan_sen    = 9;           // Ichimoku: period of Tenkan-sen
input int                  Inp_Ichimoku_kijun_sen     = 26;          // Ichimoku: period of Kijun-sen
input int                  Inp_Ichimoku_senkou_span_b = 52;          // Ichimoku: period of Senkou Span B
input    ENUM_TIMEFRAMES         IchimokuTF           = PERIOD_CURRENT;  //Ichimoku Timeframe
int      handle_iIchimoku;                      // variable for storing the handle of the iIchimoku indicator
string IchimokuSignal = "NoSignal";

//ichimoku


input double   MaxLots                    = 5.0;   // Max volume of position
input double   Doble                      = 1.6;   // Lot coefficient
//---
ulong          m_magic=491757897;                  // magic number
ulong          m_slippage=30;                      // slippage

double         ExtStopLoss=0.0;
double         ExtTakeProfit=0.0;
double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;
double         ExtIntervalPositions=0.0;
double         m_last_price_deal_entry_in=0.0;

int            handle_iCustom;                     // variable for storing the handle of the iMACD indicator 
double         m_adjusted_point;                   // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";

   if(InpLots>0.0)
      if(!CheckVolumeValue(InpLots,err_text))
        {
         Print(err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
//---
   m_trade.SetExpertMagicNumber(m_magic);
//---
   if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
//---
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss          =InpStopLoss         * m_adjusted_point;
   ExtTakeProfit        =InpTakeProfit       * m_adjusted_point;
   ExtTrailingStop      =InpTrailingStop     * m_adjusted_point;
   ExtTrailingStep      =InpTrailingStep     * m_adjusted_point;
   ExtIntervalPositions =InpIntervalPositions*m_adjusted_point;
//---
   if(InpLots<=0.0)
     {
      if(!m_money.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
         return(INIT_FAILED);
      m_money.Percent(Risk);
     }
//--- create handle of the indicator iMACD
   handle_iCustom=iCustom(m_symbol.Name(),Period(),"zerolag_macd",MACD_fast_ema_period,MACD_slow_ema_period,MACD_signal_period,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iCustom==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//ichimoku
   handle_iIchimoku=iIchimoku(m_symbol.Name(),IchimokuTF,Inp_Ichimoku_tenkan_sen,
                              Inp_Ichimoku_kijun_sen,Inp_Ichimoku_senkou_span_b);
//--- if the handle is not created
   if(handle_iIchimoku==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iIchimoku indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(IchimokuTF),
                  GetLastError());
      return(INIT_FAILED);
     }
//ichimoku

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
//   if(m_account.Balance()<1000)
//      ExpertRemove();
//---
//ichimoku
   IchimokuSignal = "NoSignal";
   SearchIchimokuSignals();
//ichimoku
   bool  continue_opening  = true;
   int   open_positions    = CalculateAllPositions();
   int   conditions_trades = 3;

   if(open_positions>InpMaxPositions)
      continue_opening=false;
//---
   double main_0=iCustomGet(MAIN_LINE,0);
   double main_1=iCustomGet(MAIN_LINE,1);
   if(main_0==0.0 || main_1==0.0)
      return;
if(TradeSignal == 1)
  {
//--- conditions_trades: 1 -> sell; 2 -> buy; 
   if(main_0>main_1)
      conditions_trades=2;
   else if(main_0<main_1)
      conditions_trades=1;
   if(InpReverseCondition)
     {
      if(conditions_trades==1)
         conditions_trades=2;
      else if(conditions_trades==2)
         conditions_trades=1;
     }
   if(conditions_trades!=3 && open_positions>InpMaxPositions)
      CloseMinimumProfit();

         
  }
if(TradeSignal == 2)
  {
//--- conditions_trades: 1 -> sell; 2 -> buy; 
   if(IchimokuSignal == "Buy")
      conditions_trades=2;
   else if(IchimokuSignal == "Sell")
      conditions_trades=1;
   if(InpReverseCondition)
     {
      if(conditions_trades==1)
         conditions_trades=2;
      else if(conditions_trades==2)
         conditions_trades=1;
     }
   if(conditions_trades!=3 && open_positions>InpMaxPositions)
      CloseMinimumProfit();         
  }

if(TradeSignal == 3)
  {
//--- conditions_trades: 1 -> sell; 2 -> buy; 
   if(IchimokuSignal == "Buy" && (main_0>main_1))
      conditions_trades=2;
   else if(IchimokuSignal == "Sell" && (main_0<main_1))
      conditions_trades=1;
   if(InpReverseCondition)
     {
      if(conditions_trades==1)
         conditions_trades=2;
      else if(conditions_trades==2)
         conditions_trades=1;
     }
   if(conditions_trades!=3 && open_positions>InpMaxPositions)
      CloseMinimumProfit();         
  }
//--- if we have opened positions we take care of them
   Trailing();
//---
//   string text="";
//
//   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
//      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
//         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
//            text=text+"\n"+"#"+IntegerToString(i)+", time open "+TimeToString(m_position.Time(),TIME_DATE|TIME_MINUTES);
//   Comment(text);
//---
   double profit_all_positions=ProfitAllPositions();

   if(open_positions>InpPosProtect && InpAccountProtection)
     {
      if(profit_all_positions>=InpSecureProfit)
        {
         //--- 
         CloseMaximumProfit();
         return;
        }
     }
//--- check open buy
   if(conditions_trades==2 && continue_opening)
     {
      if(!RefreshRates())
         return;
      double check_step_buy=ExtIntervalPositions*MathPow(InpCoeffIntervalPositions,open_positions);
      if(m_last_price_deal_entry_in-m_symbol.Ask()>=check_step_buy)
        {
         double lot_coefficient=(open_positions==0)?1.0:MathPow(Doble,open_positions+1);
         double sl=(InpStopLoss==0.0)?0.0:m_symbol.Ask()-ExtStopLoss;
         double tp=0.0;
         if(InpTakeProfit!=0)
            tp=m_symbol.Ask()+ExtTakeProfit*MathPow(InpCoeffTakeProfit,open_positions+1);
         OpenBuy(sl,tp,lot_coefficient);
         return;
        }
     }
//--- check open sell
   if(conditions_trades==1 && continue_opening)
     {
      if(!RefreshRates())
         return;
      double check_step_sell=ExtIntervalPositions*MathPow(InpCoeffIntervalPositions,open_positions);
      if(m_symbol.Bid()-m_last_price_deal_entry_in>=check_step_sell)
        {
         double lot_coefficient=(open_positions==0)?1.0:MathPow(Doble,open_positions+1);
         double sl=(InpStopLoss==0.0)?0.0:m_symbol.Bid()+ExtStopLoss;
         double tp=0.0;
         if(InpTakeProfit!=0)
            tp=m_symbol.Bid()-ExtTakeProfit*MathPow(InpCoeffTakeProfit,open_positions+1);
         OpenSell(sl,tp,lot_coefficient);
         return;
        }
     }
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
      long     deal_ticket       =0;
      long     deal_order        =0;
      long     deal_time         =0;
      long     deal_time_msc     =0;
      long     deal_type         =-1;
      long     deal_entry        =-1;
      long     deal_magic        =0;
      long     deal_reason       =-1;
      long     deal_position_id  =0;
      double   deal_volume       =0.0;
      double   deal_price        =0.0;
      double   deal_commission   =0.0;
      double   deal_swap         =0.0;
      double   deal_profit       =0.0;
      string   deal_symbol       ="";
      string   deal_comment      ="";
      string   deal_external_id  ="";
      if(HistoryDealSelect(trans.deal))
        {
         deal_ticket       =HistoryDealGetInteger(trans.deal,DEAL_TICKET);
         deal_order        =HistoryDealGetInteger(trans.deal,DEAL_ORDER);
         deal_time         =HistoryDealGetInteger(trans.deal,DEAL_TIME);
         deal_time_msc     =HistoryDealGetInteger(trans.deal,DEAL_TIME_MSC);
         deal_type         =HistoryDealGetInteger(trans.deal,DEAL_TYPE);
         deal_entry        =HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
         deal_magic        =HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
         deal_reason       =HistoryDealGetInteger(trans.deal,DEAL_REASON);
         deal_position_id  =HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID);

         deal_volume       =HistoryDealGetDouble(trans.deal,DEAL_VOLUME);
         deal_price        =HistoryDealGetDouble(trans.deal,DEAL_PRICE);
         deal_commission   =HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
         deal_swap         =HistoryDealGetDouble(trans.deal,DEAL_SWAP);
         deal_profit       =HistoryDealGetDouble(trans.deal,DEAL_PROFIT);

         deal_symbol       =HistoryDealGetString(trans.deal,DEAL_SYMBOL);
         deal_comment      =HistoryDealGetString(trans.deal,DEAL_COMMENT);
         deal_external_id  =HistoryDealGetString(trans.deal,DEAL_EXTERNAL_ID);
        }
      else
         return;
      if(deal_symbol==m_symbol.Name() && deal_magic==m_magic)
        {
         if(deal_entry==DEAL_ENTRY_OUT)
           {
            datetime last_time=D'2015.01.01 00:00';
            double   last_price=0.0;
            for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
               if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
                  if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
                    {
                     if(m_position.Time()>last_time)
                       {
                        last_time=m_position.Time();
                        last_price=m_position.PriceOpen();
                       }
                    }
            if(last_time!=D'2015.01.01 00:00')
               m_last_price_deal_entry_in=last_price;
            else
               m_last_price_deal_entry_in=0.0;
           }
         else if(deal_entry==DEAL_ENTRY_IN)
           {
            m_last_price_deal_entry_in=deal_price;
           }
        }
     }
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
//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
// double min_volume=m_symbol.LotsMin();
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
// double max_volume=m_symbol.LotsMax();
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
// double volume_step=m_symbol.LotsStep();
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                     volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Checks if the specified filling mode is allowed                  | 
//+------------------------------------------------------------------+ 
bool IsFillingTypeAllowed(int fill_type)
  {
//--- Obtain the value of the property that describes allowed filling modes 
   int filling=m_symbol.TradeFillFlags();
//--- Return true, if mode fill_type is allowed 
   return((filling & fill_type)==fill_type);
  }
//+------------------------------------------------------------------+
//| Lot Check                                                        |
//+------------------------------------------------------------------+
double LotCheck(double lots)
  {
//--- calculate maximum volume
   double volume=NormalizeDouble(lots,2);
   double stepvol=m_symbol.LotsStep();
   if(stepvol>0.0)
      volume=stepvol*MathFloor(volume/stepvol);
//---
   double minvol=m_symbol.LotsMin();
   if(volume<minvol)
      volume=0.0;
//---
   double maxvol=m_symbol.LotsMax();
   if(volume>maxvol)
      volume=maxvol;
   return(volume);
  }
//+------------------------------------------------------------------+
//| Calculate all positions                                          |
//+------------------------------------------------------------------+
int CalculateAllPositions()
  {
   int total=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            total++;
//---
   return(total);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iCustom                             |
//|  the buffer numbers are the following:                           |
//|   0 - MAIN_LINE, 1 - SIGNAL_LINE                                 |
//+------------------------------------------------------------------+
double iCustomGet(const int buffer,const int index)
  {
   double Custom[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iCustom array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iCustom,buffer,index,1,Custom)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iCustom indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Custom[0]);
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(ExtTrailingStop==0)
      return;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                     continue;
                    }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStop+ExtTrailingStep)
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStop+ExtTrailingStep))) || 
                     (m_position.StopLoss()==0))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }

           }
  }
//+------------------------------------------------------------------+
//| Profit all positions                                             |
//+------------------------------------------------------------------+
double  ProfitAllPositions()
  {
   double profit=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            profit+=m_position.Commission()+m_position.Swap()+m_position.Profit();
//---
   return(profit);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp,double lot_coefficient)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double check_open_long_lot=0.0;
   if(InpLots<=0.0)
     {
      check_open_long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
      Print("sl=",DoubleToString(sl,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(check_open_long_lot,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
      if(check_open_long_lot==0.0)
         return;
     }
   else
      check_open_long_lot=InpLots;
   check_open_long_lot=LotCheck(check_open_long_lot*lot_coefficient);
   if(check_open_long_lot==0.0)
      return;
   if(check_open_long_lot>MaxLots)
      return;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_long_lot,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=check_open_long_lot)
        {
         if(m_trade.Buy(check_open_long_lot,NULL,m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               //PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               //PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            //PrintResult(m_trade,m_symbol);
           }
        }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp,double lot_coefficient)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double check_open_short_lot=0.0;
   if(InpLots<=0.0)
     {
      check_open_short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
      Print("sl=",DoubleToString(sl,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(check_open_short_lot,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
      if(check_open_short_lot==0.0)
         return;
     }
   else
      check_open_short_lot=InpLots;
   check_open_short_lot=LotCheck(check_open_short_lot*lot_coefficient);
   if(check_open_short_lot==0.0)
      return;
   if(check_open_short_lot>MaxLots)
      return;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_short_lot,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=check_open_short_lot)
        {
         if(m_trade.Sell(check_open_short_lot,NULL,m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               //PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               //PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            //PrintResult(m_trade,m_symbol);
           }
        }
//---
  }
//+------------------------------------------------------------------+
//| Close maximum profit                                             |
//+------------------------------------------------------------------+
void CloseMaximumProfit()
  {
   double max_profit=0.0;
   ulong ticket=ULONG_MAX;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            double profit=m_position.Commission()+m_position.Swap()+m_position.Profit();
            if(profit>max_profit)
              {
               max_profit=profit;
               ticket=m_position.Ticket();
              }
           }
   if(ticket!=ULONG_MAX)
      m_trade.PositionClose(ticket);
  }
//+------------------------------------------------------------------+
//| Close minimum profit                                             |
//+------------------------------------------------------------------+
void CloseMinimumProfit()
  {
   double min_profit=0.0;
   ulong ticket=ULONG_MAX;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            double profit=m_position.Commission()+m_position.Swap()+m_position.Profit();
            if(profit<min_profit)
              {
               min_profit=profit;
               ticket=m_position.Ticket();
              }
           }
   if(ticket!=ULONG_MAX)
      m_trade.PositionClose(ticket);
  }
//+------------------------------------------------------------------+
//ichimoku
//+------------------------------------------------------------------+
//| Search trading signals                                           |
//+------------------------------------------------------------------+
bool SearchIchimokuSignals(void)
  {
//---
   double tenkan[],kijun[],spana[],spanb[],chinkou[];
   MqlRates rates[];
   ArraySetAsSeries(tenkan,true);
   ArraySetAsSeries(kijun,true);
   ArraySetAsSeries(spana,true);
   ArraySetAsSeries(spanb,true);
   ArraySetAsSeries(chinkou,true);
   ArraySetAsSeries(rates,true);
   int start_pos=0,count=6;
   if(!iGetArrayIchimoku(handle_iIchimoku,TENKANSEN_LINE,start_pos,count,tenkan) ||
      !iGetArrayIchimoku(handle_iIchimoku,KIJUNSEN_LINE,start_pos,count,kijun) ||
      !iGetArrayIchimoku(handle_iIchimoku,SENKOUSPANA_LINE,start_pos,count,spana) ||
      !iGetArrayIchimoku(handle_iIchimoku,SENKOUSPANB_LINE,start_pos,count,spanb) ||
      !iGetArrayIchimoku(handle_iIchimoku,CHIKOUSPAN_LINE,start_pos,count,chinkou) ||
      CopyRates(m_symbol.Name(),IchimokuTF,start_pos,count,rates)!=count)
     {
      return(false);
     }
//--- BUY Signal
   if((tenkan[2]<=kijun[2] && tenkan[1]>kijun[1] && m_symbol.Ask()>spana[2] && m_symbol.Ask()>spanb[2] && rates[1].open<rates[1].close))
      //   if((tenkan[2]<=kijun[2] && tenkan[1]>kijun[1])) //&& m_symbol.Ask()>spana[2] && m_symbol.Ask()>spanb[2] && rates[1].open<rates[1].close))
     {
      IchimokuSignal = "Buy";
      Print("IchimokuSignal BUY");
      return(true);

     }
//--- SELL Signal
   if((tenkan[2]>=kijun[2] && tenkan[1]<kijun[1] && m_symbol.Bid()<spana[2] && m_symbol.Bid()<spanb[2] && rates[1].open>rates[1].close))
      //  if((tenkan[2]>=kijun[2] && tenkan[1]<kijun[1])) //&& m_symbol.Bid()<spana[2] && m_symbol.Bid()<spanb[2] && rates[1].open>rates[1].close))
     {
      IchimokuSignal = "Sell";
      Print("IchimokuSignal SELL");
      return(true);

     }
//---
   return(true);
  }

//+------------------------------------------------------------------+
//| Get value of buffers                                             |
//+------------------------------------------------------------------+
bool iGetArrayIchimoku(const int handle,const int buffer,const int start_pos,
                       const int count,double &arr_buffer[])
  {
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
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
      PrintFormat("ERROR! EA: %s, FUNCTION: %s, amount to copy: %d, copied: %d, error code %d",
                  __FILE__,__FUNCTION__,count,copied,GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
     }
   return(result);
  }

//ichimoku

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   double  param = 0.0;

//  Balance max + min Drawdown + Trades Number:
   double  balance = TesterStatistics(STAT_PROFIT);
   double  min_dd = TesterStatistics(STAT_BALANCE_DD);
   if(min_dd > 0.0)
     {
      min_dd = 1.0 / min_dd;
     }
   double  trades_number = TesterStatistics(STAT_TRADES);
   param = balance * min_dd * (trades_number);

   return(param);
  }
//+------------------------------------------------------------------+