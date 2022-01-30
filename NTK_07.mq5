//+------------------------------------------------------------------+
//|                              NTK 07(barabashkakvn's edition).mq5 |
//|                                                            runik |
//|                                                  ngb2008@mail.ru |
//+------------------------------------------------------------------+
#property copyright "runik"
#property link      "ngb2008@mail.ru"
#property version   "1.001"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
#include <Expert\Money\MoneyFixedRisk.mqh>
CPositionInfo  m_position;                      // trade position object
CTrade         m_trade;                         // trading object
CSymbolInfo    m_symbol;                        // symbol info object
CAccountInfo   m_account;                       // account info wrapper
CDealInfo      m_deal;                          // deals object
COrderInfo     m_order;                         // pending orders object
CMoneyFixedMargin *m_money_fixed_margin;
CMoneyFixedRisk *m_money_fixed_risk;
//+------------------------------------------------------------------+
//| Enum money management                                            |
//+------------------------------------------------------------------+
enum ENUM_MM
  {
   FixedLot    = 0,  // Fixed Lot
   FixedMargin = 1,  // Fixed Margin
   FixedRisk   = 2,  // Fixed Risk
  };
//+------------------------------------------------------------------+
//| Enum hours                                                       |
//+------------------------------------------------------------------+
enum ENUM_HOURS
  {
   hour_00  =0,   // 00
   hour_01  =1,   // 01
   hour_02  =2,   // 02
   hour_03  =3,   // 03
   hour_04  =4,   // 04
   hour_05  =5,   // 05
   hour_06  =6,   // 06
   hour_07  =7,   // 07
   hour_08  =8,   // 08
   hour_09  =9,   // 09
   hour_10  =10,  // 10
   hour_11  =11,  // 11
   hour_12  =12,  // 12
   hour_13  =13,  // 13
   hour_14  =14,  // 14
   hour_15  =15,  // 15
   hour_16  =16,  // 16
   hour_17  =17,  // 17
   hour_18  =18,  // 18
   hour_19  =19,  // 19
   hour_20  =20,  // 20
   hour_21  =21,  // 21
   hour_22  =22,  // 22
   hour_23  =23,  // 23
  };
//+------------------------------------------------------------------+
//| Enum type of trade                                               |
//+------------------------------------------------------------------+
enum ENUM_TYPE_TRADE
  {
   EdgesOfRange   = 0,  // trade from edges of range
   CenterOfRange  = 1,  // trade from the centre of range
  };
//---- input parameters
input string      g1="Main settings"; // - Main settings -
input double      InpLots              = 1.0;      // Fixed Lot
input double      InpTotalLots         = 7.0;      // Max total lots
input uchar       InpMaxPositions      = 4;        // Max total Positions
input ushort      InpNetStep           = 5;        // Net step (in pips)
input ushort      InpStopLoss          = 11;       // Stop Loss (in pips)
input ushort      InpTakeProfit        = 30;       // Take Profit (in pips)
input double      InpLotIncreaseRate   = 1.7;      // Lot increase rate
input bool        InpTrailingAtHighLow = true;     // Trailing at High and Low prices
input bool        InpUseTrailingMA     = false;    // Trailing at Moving Average
input ushort      InpTrailingStop      = 8;        // Trailing Stop (in pips), trailing step = trsailing step / 2
sinput string     g2="Money management"; // - Money management -
input ENUM_MM     InpMoneyManagement   = FixedRisk;// Money management
input double      Risk                 = 5;        // Risk in % for a deal (only for "Fixed Margin" and "Fixed Risk")
input double      InpMinFreeMargin     = 5000.0;   // Min FreeMargin
sinput string     g3="Moving Average"; // - Moving Average -
input int         Inp_ma_period        = 100;      // MA: averaging period
input int         Inp_ma_shift         = 0;        // MA: horizontal shift
input ENUM_MA_METHOD Inp_ma_method=MODE_SMMA;// MA: smoothing type
input ENUM_APPLIED_PRICE Inp_applied_price=PRICE_CLOSE;// MA: type of price
sinput string     bb="Low-valued variables"; // - Low-valued variables -
input ENUM_HOURS  InpHourStart         = hour_00;  // Hour start  
input ENUM_HOURS  InpHourEnd           = hour_23;  // Hour end
input uchar       InpBars              = 0;        // Period in bars. Period "1" and "2" - are equivalent!
input ENUM_TYPE_TRADE InpTypeTrade=EdgesOfRange;   // Type of trade
input ulong       m_magic              =468451380; // magic number
//---
ulong             m_slippage=30;                   // slippage
//---
double            ExtNetStep=0.0;
double            ExtStopLoss=0.0;
double            ExtTakeProfit=0.0;
double            ExtTrailingStop=0.0;
uchar             ExtBars=0;

int               handle_iMA;                      // variable for storing the handle of the iMA indicator

double            m_adjusted_point;                // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpNetStep==0)
     {
      string text="Attention! \"Net step\" can not be zero!";
      Alert(text);
      Print(text);
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpStopLoss==0 && (InpMoneyManagement==FixedMargin || InpMoneyManagement==FixedRisk))
     {
      string text="Attention! \"Stop Loss\" can not be equal to zero, if \"Money management\" is equal to \"Fixed Margin\" or \"Fixed Risk\"!";
      Alert(text);
      Print(text);
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpTrailingStop==0)
     {
      string text="Attention! \"Trailing Stop\" can not be zero!";
      Alert(text);
      Print(text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   int all_trailing=0;
   all_trailing=(InpTrailingAtHighLow)?all_trailing+1:all_trailing;
   all_trailing=(InpUseTrailingMA)?all_trailing+1:all_trailing;
   if(all_trailing>1)
     {
      string text="Attention! You use more than one type of trailing!";
      Alert(text);
      Print(text);
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpHourStart>=InpHourEnd)
     {
      string text="Attention! \"Hour start\" >= \"Hour end\"";
      Alert(text);
      Print(text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(InpMoneyManagement==FixedLot)
     {
      if(InpLots<=0.0)
        {
         Print("The \"Fixed Lot\" can't be smaller or equal to zero");
         return(INIT_PARAMETERS_INCORRECT);
        }
     }
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();
   if(InpMoneyManagement==FixedLot)
     {
      string err_text="";
      if(!CheckVolumeValue(InpLots,err_text))
        {
         Print(err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
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

   ExtNetStep        =InpNetStep       *m_adjusted_point;
   ExtStopLoss       =InpStopLoss      *m_adjusted_point;
   ExtTakeProfit     =InpTakeProfit    *m_adjusted_point;
   ExtTrailingStop   =InpTrailingStop  *m_adjusted_point;
   ExtBars=InpBars;
   if(ExtBars==1)
      ExtBars=2;
//---
   if(InpMoneyManagement==FixedMargin)
     {
      delete m_money_fixed_margin;
      m_money_fixed_margin=new CMoneyFixedMargin;
      if(m_money_fixed_margin==NULL)
        {
         Print("Object CMoneyFixedMargin id POINTER_INVALID");
         return(INIT_FAILED);
        }
      if(!m_money_fixed_margin.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
         return(INIT_FAILED);
      m_money_fixed_margin.Percent(Risk);
     }
   if(InpMoneyManagement==FixedRisk)
     {
      delete m_money_fixed_risk;
      m_money_fixed_risk=new CMoneyFixedRisk;
      if(m_money_fixed_risk==NULL)
        {
         Print("Object CMoneyFixedRisk id POINTER_INVALID");
         return(INIT_FAILED);
        }
      if(!m_money_fixed_risk.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
         return(INIT_FAILED);
      m_money_fixed_risk.Percent(Risk);
     }
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),Period(),Inp_ma_period,Inp_ma_shift,Inp_ma_method,Inp_applied_price);
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
   delete(m_money_fixed_margin);
   delete(m_money_fixed_risk);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   MqlDateTime str1;
   TimeToStruct(TimeCurrent(),str1);
//--- we do not work on weekends
   if(str1.day_of_week==0 || str1.day_of_week==6)
      return;
//---
   static datetime last_time=0;
   datetime time_current=TimeCurrent();
   if((long)(time_current-last_time)<10)
     {
      return;
     }
   last_time=time_current;
//---
   static int count_errors=0;
   if(m_account.FreeMargin()<InpMinFreeMargin)
     {
      if(count_errors==0)
        {
         PrintFormat("We have no money. FreeMargin %.2f < \"Min FreeMargin\" %.2f",m_account.FreeMargin(),InpMinFreeMargin);
         count_errors=1;
        }
      return;
     }
   count_errors=0;
//---
   double buylot        =0.0; double buyprice      =0.0; double buystoplot    =0.0; double buystopprice  =0.0;
   double selllot       =0.0; double sellprice     =0.0; double sellstoplot   =0.0; double sellstopprice =0.0;
   double buysl         =0.0; double buytp         =0.0; double sellsl        =0.0; double selltp=0.0;

   ulong buy_ticket  =ULONG_MAX; ulong buy_stop_ticket   =ULONG_MAX;
   ulong sell_ticket =ULONG_MAX; ulong sell_stop_ticket  =ULONG_MAX;
//---
   int count_buy=0;
   int count_sell=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               count_buy++;
               //--- remember the parameters of the largest BUY position
               if(buylot<m_position.Volume())
                 {
                  buylot      =m_position.Volume();
                  buyprice    =m_position.PriceOpen();
                  buy_ticket  =m_position.Ticket();
                  buysl       =m_position.StopLoss();
                  buytp       =m_position.TakeProfit();
                 }
              }
            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               count_sell++;
               //--- remember the parameters of the largest position SELL
               if(selllot<m_position.Volume())
                 {
                  selllot     =m_position.Volume();
                  sellprice   =m_position.PriceOpen();
                  sell_ticket =m_position.Ticket();
                  sellsl      =m_position.StopLoss();
                  selltp      =m_position.TakeProfit();
                 }
              }
           }
   int count_buy_stop=0;
   int count_sell_stop=0;
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i)) // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
           {
            if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
              {
               count_buy_stop++;
               buystoplot        =m_order.VolumeInitial();
               buystopprice      =m_order.PriceOpen();
               buy_stop_ticket   =m_order.Ticket();
              }
            if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
              {
               count_sell_stop++;
               sellstoplot       =m_order.VolumeInitial();
               sellstopprice     =m_order.PriceOpen();
               sell_stop_ticket  =m_order.Ticket();
              }
           }
//--- begin!
   if(!RefreshRates())
      return;
   if(count_buy+count_sell+count_buy_stop+count_sell_stop==0)
     {
      if(str1.hour<InpHourStart || str1.hour>InpHourEnd)
         return;
      double ssmax=iHigh(m_symbol.Name(),Period(),1);
      double ssmin=iLow(m_symbol.Name(),Period(),1);
      if(ssmax==0.0 || ssmin==0.0)
         return;
      for(int x=2;x<=ExtBars;x++)
        {
         double high=iHigh(m_symbol.Name(),Period(),x);
         double low=iLow(m_symbol.Name(),Period(),x);
         if(high==0.0 || low==0.0)
            return;
         if(ssmax<high)
            ssmax=high;
         if(ssmin>low)
            ssmin=low;
        }
      //---
      double price_buy  =m_symbol.Ask()+ExtNetStep;
      double sl_buy     =(InpStopLoss==0)?0.0:m_symbol.Ask()+ExtNetStep-ExtStopLoss;
      double tp_buy     =(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtNetStep+ExtTakeProfit;
      double lot_buy    =CalculatLot(price_buy,POSITION_TYPE_BUY,sl_buy,tp_buy);
      if(lot_buy==0.0)
        {
         Print("CalculatLot(POSITION_TYPE_BUY)==0.0");
         return;
        }
      lot_buy=LotCheck(lot_buy);
      if(lot_buy==0.0)
        {
         Print("LotCheck(calculate lot BUY)==0.0");
         return;
        }
      //---
      double price_sell =m_symbol.Bid()-ExtNetStep;
      double sl_sell    =(InpStopLoss==0)?0.0:m_symbol.Bid()-ExtNetStep+ExtStopLoss;
      double tp_sell    =(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtNetStep-ExtTakeProfit;
      double lot_sell   =CalculatLot(price_sell,POSITION_TYPE_SELL,sl_sell,tp_sell);
      if(lot_sell==0.0)
        {
         Print("CalculatLot(POSITION_TYPE_SELL)==0.0");
         return;
        }
      lot_sell=LotCheck(lot_sell);
      if(lot_sell==0.0)
        {
         Print("LotCheck(calculate lot SELL)==0.0");
         return;
        }
      if(lot_buy+lot_sell>InpTotalLots)
        {
         Print(" Calculate lot BUY ",DoubleToString(lot_buy,2),
               " + calculate lot SELL ",DoubleToString(lot_sell,2)," > \"Max total lots\"",InpTotalLots);
         return;
        }
      //---
      bool one=(InpTypeTrade==EdgesOfRange && (m_symbol.Ask()>ssmax || m_symbol.Bid()<ssmin));
      bool two=(InpTypeTrade==CenterOfRange &&
                ((m_symbol.Ask()+m_symbol.Bid())/2.0<=(ssmax+ssmin)/2.0+1.0*m_adjusted_point &&
                (m_symbol.Ask()+m_symbol.Bid())/2.0>=(ssmax+ssmin)/2.0-1.0*m_adjusted_point));
      if(one || two || ExtBars==0)
        {
         if(m_trade.BuyStop(lot_buy,price_buy,m_symbol.Name(),sl_buy,tp_buy))
            Print("BUY_STOP - > true. ticket of order = ",m_trade.ResultOrder());
         else
            Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of order: ",m_trade.ResultOrder());
         if(m_trade.SellStop(lot_sell,price_sell,m_symbol.Name(),sl_sell,tp_sell))
            Print("SELL_STOP - > true. ticket of order = ",m_trade.ResultOrder());
         else
            Print("SELL_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of order: ",m_trade.ResultOrder());
         return;
        }
     }
//--- if there is a SELL position, then the pending order SELL_STOP has triggered
//--- and you need to remove the opportunity to open the BUY position
   if(sell_ticket!=ULONG_MAX) // если цена пошла вниз
     {
      if(buy_stop_ticket!=ULONG_MAX) // delete BUY_STOP
        {
         m_trade.OrderDelete(buy_stop_ticket);
         return;
        }
      if(buy_ticket!=ULONG_MAX) // close position BUY
        {
         m_trade.PositionClose(buy_ticket);
         return;
        }
      if(sell_stop_ticket==ULONG_MAX) // there are no pending orders and there is at least a SELL position
        {
         double price_sell    =sellprice-ExtNetStep;
         double stops_freeze  =(m_symbol.StopsLevel()>m_symbol.FreezeLevel())?(double)m_symbol.StopsLevel():(double)m_symbol.FreezeLevel();
         stops_freeze         =(stops_freeze==0.0)?m_symbol.Bid()-(m_symbol.Ask()-m_symbol.Bid())*3.0:m_symbol.Bid()-stops_freeze*m_symbol.Point();
         if(price_sell>stops_freeze)
            return;
         price_sell           =m_symbol.NormalizePrice(sellprice-ExtNetStep);
         double sl_sell       =(InpStopLoss==0)?0.0:m_symbol.NormalizePrice(sellprice-ExtNetStep+ExtStopLoss);
         double tp_sell       =(InpTakeProfit==0)?0.0:m_symbol.NormalizePrice(sellprice-ExtNetStep-ExtTakeProfit);
         double lot_sell      =selllot*InpLotIncreaseRate;
         //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
         double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot_sell,price_sell,ORDER_TYPE_SELL);
         Print("CheckVolume: ",
               ", Lot sell * \"Lot increase rate\"= ",DoubleToString(lot_sell,2),
               ", CheckVolume=",DoubleToString(check_volume_lot,2));
         if(check_volume_lot==0.0 || check_volume_lot<lot_sell)
            return;
         lot_sell=LotCheck(lot_sell);
         if(lot_sell==0.0)
            return;
         if(buylot+selllot+buystoplot+sellstoplot>InpTotalLots)
            return;
         if(m_trade.SellStop(lot_sell,price_sell,m_symbol.Name(),sl_sell,tp_sell))
            Print("SELL_STOP - > true. ticket of order = ",m_trade.ResultOrder());
         else
            Print("SELL_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of order: ",m_trade.ResultOrder());
         return;
        }
     }
//--- if there is a position BUY - it means that the suspended order BUY_STOP
//--- and you need to remove the opportunity to open the SELL position
   if(buy_ticket!=ULONG_MAX) // если цена пошла вверх
     {
      if(sell_stop_ticket!=ULONG_MAX) // remove SELL_STOP
        {
         m_trade.OrderDelete(sell_stop_ticket);
         return;
        }
      if(sell_ticket!=ULONG_MAX) // close the SELL position
        {
         m_trade.PositionClose(sell_ticket);
         return;
        }
      if(buy_stop_ticket==ULONG_MAX) // there are no pending orders and there is at least a BUY position
        {
         double price_buy     =buyprice+ExtNetStep;
         double stops_freeze  =(m_symbol.StopsLevel()>m_symbol.FreezeLevel())?(double)m_symbol.StopsLevel():(double)m_symbol.FreezeLevel();
         stops_freeze         =(stops_freeze==0.0)?m_symbol.Ask()+(m_symbol.Ask()-m_symbol.Bid())*3.0:m_symbol.Ask()+stops_freeze*m_symbol.Point();
         if(price_buy<stops_freeze)
            return;
         price_buy=m_symbol.NormalizePrice(buyprice+ExtNetStep);
         double sl_buy     =(InpStopLoss==0)?0.0:m_symbol.NormalizePrice(buyprice+ExtNetStep-ExtStopLoss);
         double tp_buy     =(InpTakeProfit==0)?0.0:m_symbol.NormalizePrice(buyprice+ExtNetStep+ExtTakeProfit);
         double lot_buy=buylot*InpLotIncreaseRate;
         //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
         double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot_buy,price_buy,ORDER_TYPE_BUY);
         Print("CheckVolume: ",
               ", Lot buy * \"Lot increase rate\"= ",DoubleToString(lot_buy,2),
               ", CheckVolume=",DoubleToString(check_volume_lot,2));
         if(check_volume_lot==0.0 || check_volume_lot<lot_buy)
            return;
         lot_buy=LotCheck(lot_buy);
         if(lot_buy==0.0)
            return;
         if(buylot+selllot+buystoplot+sellstoplot>InpTotalLots)
            return;
         if(m_trade.BuyStop(lot_buy,price_buy,m_symbol.Name(),sl_buy,tp_buy))
            Print("BUY_STOP - > true. ticket of order = ",m_trade.ResultOrder());
         else
            Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of order: ",m_trade.ResultOrder());
         return;
        }
     }
//---
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY && m_position.PriceCurrent()>m_position.PriceOpen()) // позиция должна быть как минимум прибыльная
              {
               double sl=0.0;
               if(InpTrailingAtHighLow)
                 {
                  double low_1=iLow(m_symbol.Name(),Period(),1);
                  if(low_1==0.0)
                     continue;
                  double delta=m_position.PriceCurrent()-ExtTrailingStop-ExtTrailingStop/2.0;
                  if((m_position.StopLoss()!=0.0 && delta>low_1 && m_position.StopLoss()<low_1 && !CompareDoubles(m_position.StopLoss(),low_1,m_symbol.Digits())) ||
                     (m_position.StopLoss()==0.0 && delta>low_1))
                    {
                     sl=low_1;
                    }
                 }
               else if(InpUseTrailingMA)
                 {
                  double ma_1=iMAGet(0);
                  if(ma_1==0.0)
                     continue;
                  double delta=m_position.PriceCurrent()-ExtTrailingStop-ExtTrailingStop/2.0;
                  if((m_position.StopLoss()!=0.0 && delta>ma_1 && m_position.StopLoss()<ma_1 && !CompareDoubles(m_position.StopLoss(),ma_1,m_symbol.Digits())) ||
                     (m_position.StopLoss()==0.0 && delta>ma_1))
                    {
                     sl=ma_1;
                    }
                 }
               else if(InpTrailingStop!=0)
                 {
                  double delta=m_position.PriceCurrent()-ExtTrailingStop-ExtTrailingStop/2.0;
                  if((m_position.StopLoss()!=0.0 && delta>m_position.StopLoss()) ||
                     (m_position.StopLoss()==0.0 && delta>m_position.PriceOpen()))
                    {
                     double temp_sl=m_position.PriceCurrent()-ExtTrailingStop; // гарантия прибыльности на новом уровне Stop Loss
                     if(temp_sl>m_position.PriceOpen() && !CompareDoubles(temp_sl,m_position.PriceOpen(),m_symbol.Digits()))
                        sl=temp_sl;
                    }
                 }
               if(sl!=0.0)
                  if(!m_trade.PositionModify(m_position.Ticket(),
                     m_symbol.NormalizePrice(sl),
                     m_position.TakeProfit()))
                     Print("Modify Buy ",m_position.Ticket(),
                           " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                           ", description of result: ",m_trade.ResultRetcodeDescription());
               continue;
              }
            else if(m_position.PositionType()==POSITION_TYPE_SELL && m_position.PriceCurrent()<m_position.PriceOpen()) // позиция должна быть как минимум прибыльная
              {
               double sl=0.0;
               if(InpTrailingAtHighLow)
                 {
                  double high_1=iHigh(m_symbol.Name(),Period(),1);
                  if(high_1==0.0)
                     continue;
                  double delta=m_position.PriceCurrent()+ExtTrailingStop+ExtTrailingStop/2.0;
                  if((m_position.StopLoss()!=0.0 && delta<high_1 && m_position.StopLoss()>high_1 && !CompareDoubles(m_position.StopLoss(),high_1,m_symbol.Digits())) ||
                     (m_position.StopLoss()==0.0 && delta<high_1))
                    {
                     sl=high_1;
                    }
                 }
               else if(InpUseTrailingMA)
                 {
                  double ma_1=iMAGet(0);
                  if(ma_1==0.0)
                     continue;
                  double delta=m_position.PriceCurrent()+ExtTrailingStop+ExtTrailingStop/2.0;
                  if((m_position.StopLoss()!=0.0 && delta<ma_1 && m_position.StopLoss()>ma_1 && !CompareDoubles(m_position.StopLoss(),ma_1,m_symbol.Digits())) ||
                     (m_position.StopLoss()==0.0 && delta<ma_1))
                    {
                     sl=ma_1;
                    }
                 }
               else if(InpTrailingStop!=0)
                  if((m_position.StopLoss()!=0.0 && m_position.PriceCurrent()+ExtTrailingStop+ExtTrailingStop/2.0<m_position.StopLoss()) ||
                     (m_position.StopLoss()==0.0 && m_position.PriceCurrent()+ExtTrailingStop+ExtTrailingStop/2.0<m_position.PriceOpen()))
                    {
                     double temp_sl=m_position.PriceCurrent()+ExtTrailingStop; // гарантия прибыльности на новом уровне Stop Loss
                     if(temp_sl<m_position.PriceOpen() && !CompareDoubles(temp_sl,m_position.PriceOpen(),m_symbol.Digits()))
                        sl=temp_sl;
                    }
               if(sl!=0.0)
                  if(!m_trade.PositionModify(m_position.Ticket(),
                     m_symbol.NormalizePrice(sl),
                     m_position.TakeProfit()))
                     Print("Modify Sell ",m_position.Ticket(),
                           " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                           ", description of result: ",m_trade.ResultRetcodeDescription());
               continue;
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
   double res=0.0;
   int losses=0.0;
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
      //if(deal_reason!=-1)
      //   DebugBreak();
      if(deal_symbol==m_symbol.Name() && deal_magic==m_magic)
         if(deal_entry==DEAL_ENTRY_OUT)
           {
            int count_buy=0;
            int count_sell=0;
            for(int i=PositionsTotal()-1;i>=0;i--)
               if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
                  if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
                    {
                     if(m_position.PositionType()==POSITION_TYPE_BUY)
                        count_buy++;
                     if(m_position.PositionType()==POSITION_TYPE_SELL)
                        count_sell++;
                    }
            if(count_buy+count_sell==0.0)
               DeleteAllOrders();
           }
     }
  }
//+------------------------------------------------------------------+
//| Calculation Net Price                                            |
//+------------------------------------------------------------------+
double CalculationNetPrice()
  {
   double total_price_multiply_volume_buy    = 0.0;
   double total_volume_buy                   = 0.0;
   double net_price_buy                      = 0.0;

   double total_price_multiply_volume_sell   = 0.0;
   double total_volume_sell                  = 0.0;
   double net_price_sell                     = 0.0;

   int total=PositionsTotal();
   for(int i=total-1;i>=0;i--)
     {
      if(!m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         break;
      if(m_position.Symbol()==Symbol())
        {
         if(m_position.PositionType()==POSITION_TYPE_BUY)
           {
            total_price_multiply_volume_buy+=m_position.PriceOpen()*m_position.Volume();
            total_volume_buy+=m_position.Volume();
           }
         else
           {
            total_price_multiply_volume_sell+=m_position.PriceOpen()*m_position.Volume();
            total_volume_sell+=m_position.Volume();
           }
        }
     }
//---
   if(total_volume_buy-total_volume_sell!=0)
     {
      double breakeven_price=(total_price_multiply_volume_buy-total_price_multiply_volume_sell)/
                             (total_volume_buy+total_volume_sell*-1);
      return(breakeven_price);
     }
//---
   return(0.0);
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
//| Calculat lot                                                     |
//+------------------------------------------------------------------+
double CalculatLot(double &price,ENUM_POSITION_TYPE pos_type,double &sl,double &tp)
  {
   price=m_symbol.NormalizePrice(price);
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
   if(pos_type==POSITION_TYPE_BUY)
     {
      double check_open_long_lot=0.0;
      if(InpMoneyManagement==FixedLot)
        {
         check_open_long_lot=InpLots;
        }
      if(InpMoneyManagement==FixedMargin)
        {
         check_open_long_lot=m_money_fixed_margin.CheckOpenLong(price,sl);
         Print("CheckOpenLong: sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenLong: ",DoubleToString(check_open_long_lot,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
         if(check_open_long_lot==0.0)
            return(0.0);
        }
      if(InpMoneyManagement==FixedRisk)
        {
         check_open_long_lot=m_money_fixed_risk.CheckOpenLong(price,sl);
         Print("CheckOpenLong: sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenLong: ",DoubleToString(check_open_long_lot,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
         if(check_open_long_lot==0.0)
            return(0.0);
        }
      //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
      double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_long_lot,price,ORDER_TYPE_BUY);
      Print("CheckVolume: ",
            ", CheckOpenLong= ",DoubleToString(check_open_long_lot,2),
            ", CheckVolume=",DoubleToString(check_volume_lot,2));
      if(check_volume_lot!=0.0)
         if(check_volume_lot>=check_open_long_lot)
            return(check_open_long_lot);
      return(0.0);
     }
//---
   if(pos_type==POSITION_TYPE_SELL)
     {
      double check_open_short_lot=0.0;
      if(InpMoneyManagement==FixedLot)
        {
         check_open_short_lot=InpLots;
        }
      if(InpMoneyManagement==FixedMargin)
        {
         check_open_short_lot=m_money_fixed_margin.CheckOpenShort(price,sl);
         Print("CheckOpenShort: sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenShort: ",DoubleToString(check_open_short_lot,2),
               ", Balance: ",       DoubleToString(m_account.Balance(),2),
               ", Equity: ",        DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ",    DoubleToString(m_account.FreeMargin(),2));
         if(check_open_short_lot==0.0)
            return(0.0);
        }
      if(InpMoneyManagement==FixedRisk)
        {
         check_open_short_lot=m_money_fixed_risk.CheckOpenShort(price,sl);
         Print("CheckOpenShort: sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenShort: ",DoubleToString(check_open_short_lot,2),
               ", Balance: ",       DoubleToString(m_account.Balance(),2),
               ", Equity: ",        DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ",    DoubleToString(m_account.FreeMargin(),2));
         if(check_open_short_lot==0.0)
            return(0.0);
        }
      //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
      double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_short_lot,price,ORDER_TYPE_SELL);
      Print("CheckVolume: ",
            ", CheckOpenShort= ",DoubleToString(check_open_short_lot,2),
            ", CheckVolume=",DoubleToString(check_volume_lot,2));
      if(check_volume_lot!=0.0)
         if(check_volume_lot>=check_open_short_lot)
            return(check_open_short_lot);
      return(0.0);
     }
//---
   return(0.0);
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
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol.LotsMin();
   if(volume<min_volume)
     {
      error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
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
//| Compare doubles                                                  |
//+------------------------------------------------------------------+
bool CompareDoubles(double number1,double number2,int digits)
  {
   if(NormalizeDouble(number1-number2,digits)==0)
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+
//| Delete all pendinf orders                                        |
//+------------------------------------------------------------------+
void DeleteAllOrders()
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i)) // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            m_trade.OrderDelete(m_order.Ticket());
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(const int index)
  {
   double MA[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iMA,0,index,1,MA)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(MA[0]);
  }
//+------------------------------------------------------------------+
