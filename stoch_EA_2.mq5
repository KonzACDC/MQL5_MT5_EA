//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

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

#include <Trade\PositionInfo.mqh>
#include<Trade/Trade.mqh>
#include <Trade\SymbolInfo.mqh>
CTrade m_trade;
CSymbolInfo    m_symbol;                     // symbol info object
CPositionInfo  m_position;                   // object of CPositionInfo class

//--- input parameters

input ushort   InpStep           = 15;       // Step between positions
input uchar    InpBarsSkipped=45;        // Number of bars to be skipped
input double   InpIncreaseFactor = 1.7;      // Volume increase factor
input double   InpMaxLot         = 6.0;      // Max volume
input double   InpMinProfit      = 10.0;     // Min profit for close all
//---
ulong          m_ticket;
ulong          m_magic=114514;            // magic number
ulong          m_slippage=8000;                // slippage

double         ExtTakeProfit=0.0;
double         ExtStopLoss=0.0;

double         ExtStep=0.0;

double         m_adjusted_point;             // point value adjusted for 3 or 5 points



input double Entrysignal = 1;
input double lotSize = 0.05;
input int staticSL = 100;
input int staticTP = 150;
//input int staticSLTP = 150;
input    ENUM_TIMEFRAMES         MACDTF           = PERIOD_CURRENT;  //MACD Timeframe
input    ENUM_TIMEFRAMES         STOTF           = PERIOD_CURRENT;  //STO Timeframe
input    ENUM_TIMEFRAMES         MACDTF2           = PERIOD_CURRENT;  //MACD2 Timeframe
input    ENUM_TIMEFRAMES         STOTF2           = PERIOD_CURRENT;  //STO2 Timeframe
input    ENUM_MA_METHOD          STOMA1            = MODE_SMA;
input    ENUM_MA_METHOD          STOMA2            = MODE_SMA;
input    ENUM_STO_PRICE          STOPRICE1         = STO_LOWHIGH ;
input    ENUM_STO_PRICE          STOPRICE2         = STO_LOWHIGH ;
input int Inp_maxpositions = 1;

input int                  Inp_Ichimoku_tenkan_sen    = 9;           // Ichimoku: period of Tenkan-sen
input int                  Inp_Ichimoku_kijun_sen     = 26;          // Ichimoku: period of Kijun-sen
input int                  Inp_Ichimoku_senkou_span_b = 52;          // Ichimoku: period of Senkou Span B
input    ENUM_TIMEFRAMES         IchimokuTF           = PERIOD_CURRENT;  //Ichimoku Timeframe

//ENUM_TIMEFRAMES         STOTF = MACDTF ;
//ENUM_TIMEFRAMES         STOTF2 = MACDTF2 ;

int maxPositions = Inp_maxpositions;

//--- input parameters
input bool Customtrailing = false;
input bool Unitrailing = false;
input uint                 InpTrailingStop      = 10;          // Trailing Stop (min distance from price to Stop Loss)
input group             "MA"
input int                  Inp_MA_ma_period     = 12;          // MA: averaging period
input int                  Inp_MA_ma_shift      = 0;           // MA: horizontal shift
input ENUM_MA_METHOD       Inp_MA_ma_method     = MODE_SMA;    // MA: smoothing type
input ENUM_APPLIED_PRICE   Inp_MA_applied_price = PRICE_CLOSE; // MA: type of price
input group             "Additional features"
input bool                 InpPrintLog          = true;       // Print log
input ulong                InpDeviation         = 10;          // Deviation
input ulong                InpMagic             = 114514;    // Magic number
//---
double   m_trailing_stop            = 0.0;      // Trailing Stop              -> double

int      handle_iMA;                            // variable for storing the handle of the iMA indicator

datetime m_prev_bars                = 0;        // "0" -> D'1970.01.01 00:00';

int      handle_iIchimoku;                      // variable for storing the handle of the iIchimoku indicator
string IchimokuSignal = "NoSignal";

//Unitrailing

enum t
  {
   b=1,     // on extremes of candles
   c=2,     // by fractals
   d=3,     // by ATR indicator
   e=4,     // by Parabolic indicator
   f=5,     // by MA indicator
   g=6,     // by percentage of profit
   i=7,     // by points
  };
extern bool    VirtualTrailingStop=false;//virtual trailing stop
input t        parameters_trailing=1;      //trailing method

extern int     delta=0;     // indent from the calculated stop loss level
extern ENUM_TIMEFRAMES TF_Tralling=0;      // timeframe of indicators (0-current)

extern int     StepTrall=1;      // stop loss move step
extern int     StartTrall=1;      // minimum trailing profit in points

color   text_color=clrGreen;     //output color

sinput string Advanced_Options="";

input int     period_ATR=14;//ATR Period (Method 3)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input double Step=0.02; //Parabolic Step (Method 4)
input double Maximum=0.2; //Parabolic Maximum (Method 4)
sinput  int     Magic= -1;//with which magic to trail (-1 is all)
extern bool    GeneralNoLoss=true;   // trail from the breakeven point
extern bool    DrawArrow=false;   // show breakeven and stop marks

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int ma_period=34;//MA period (method 5)
input ENUM_MA_METHOD ma_method=MODE_SMA; // averaging method (method 5)
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;    // price type (method 5)

input double PercetnProfit=50;//percentage of profit (method 6)

MqlTradeRequest request;  // trade request parameters
MqlTradeResult result;    // trade request result
MqlTradeCheckResult check;
//--------------------------------------------------------------------
int STOPLEVEL;
double Bid,Ask,SLB=0,SLS=0;
int slippage=100;
int maHandle;    // Moving Average indicator handle
double maVal[];  // dynamic array for storing the Moving Average indicator values for each bar
int atrHandle;    // Moving Average indicator handle
double atrVal[];  // dynamic array for storing the Moving Average indicator values for each bar
int sarHandle;    // Moving Average indicator handle
double sarVal[];  // dynamic array for storing the Moving Average indicator values for each bar
//--------------------------------------------------------------------

//Unitrailing


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   m_trade.SetExpertMagicNumber(InpMagic);
   TrailingMAInit();
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
   UnitrailInit();
   OnInitMartins();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   UnitrailDeinit();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   if(!RefreshRates())
     {
      PrevBars=0;
      return;
     }
   IchimokuSignal = "NoSignal";
   SearchIchimokuSignals();


//staticSL = staticSLTP;
//staticTP = staticSLTP;
   double macdArray[];
   double KArray[];
   double DArray[];

   double macdArray2[];
   double KArray2[];
   double DArray2[];


   ArraySetAsSeries(macdArray, true);
   ArraySetAsSeries(KArray, true);
   ArraySetAsSeries(DArray, true);

   ArraySetAsSeries(macdArray2, true);
   ArraySetAsSeries(KArray2, true);
   ArraySetAsSeries(DArray2, true);


   int MACD = iMACD(_Symbol, MACDTF, 12, 26, 9, PRICE_OPEN);
   int StochasticDef = iStochastic(_Symbol, STOTF, 5, 3, 3, STOMA1, STOPRICE1);
   int MACD2 = iMACD(_Symbol, MACDTF2, 12, 26, 9, PRICE_OPEN);
   int StochasticDef2 = iStochastic(_Symbol, STOTF2, 5, 3, 3, STOMA2, STOPRICE2);


   CopyBuffer(MACD, 0, 0, 3, macdArray);
   CopyBuffer(MACD2, 0, 0, 3, macdArray2);


   CopyBuffer(StochasticDef, 0, 0, 3, KArray);
   CopyBuffer(StochasticDef, 1, 0, 3, DArray);
   CopyBuffer(StochasticDef2, 0, 0, 3, KArray2);
   CopyBuffer(StochasticDef2, 1, 0, 3, DArray2);


   double Ask1=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid1=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
//   if(Entrysignal == 1)
//     {
//      if(maxPositions != PositionsTotal() && KArray[0] < 20 && DArray[0] < 20 && macdArray[0] > 0 && KArray2[0] < 20 && macdArray2[0] > 0)
//        {
//         m_trade.Buy(lotSize, _Symbol, Ask1, Ask1 - staticSL * _Point, Ask1 + staticTP * _Point);
//
//
//        }
//
//
//      if(maxPositions != PositionsTotal() && KArray[0] > 80 && DArray[0] > 80 && macdArray[0] < 0 && KArray2[0] > 80 && macdArray2[0] < 0)
//        {
//         m_trade.Sell(lotSize, _Symbol, Bid1, Bid1 + staticSL * _Point, Bid1 - staticTP * _Point);
//        }
//
//
//     }
//
//   if(Entrysignal == 2)
//     {
//      if(maxPositions != PositionsTotal() && IchimokuSignal == "Buy")
//        {
//         m_trade.Buy(lotSize, _Symbol, Ask1, Ask1 - staticSL * _Point, Ask1 + staticTP * _Point);
//
//
//        }
//
//
//      if(maxPositions != PositionsTotal() && IchimokuSignal == "Sell")       {
//         m_trade.Sell(lotSize, _Symbol, Bid1, Bid1 + staticSL * _Point, Bid1 - staticTP * _Point);
//        }
//
//
//     }
//
//   if(Entrysignal == 3)
//     {
//      if(maxPositions != PositionsTotal() && IchimokuSignal == "Buy" && KArray[0] < 20 && DArray[0] < 20 && macdArray[0] > 0 && KArray2[0] < 20 && macdArray2[0] > 0)
//        {
//         m_trade.Buy(lotSize, _Symbol, Ask1, Ask1 - staticSL * _Point, Ask1 + staticTP * _Point);
//
//
//        }
//
//
//      if(maxPositions != PositionsTotal() && IchimokuSignal == "Sell" && KArray[0] > 80 && DArray[0] > 80 && macdArray[0] < 0 && KArray2[0] > 80 && macdArray2[0] < 0)    
//         {
//         m_trade.Sell(lotSize, _Symbol, Bid1, Bid1 + staticSL * _Point, Bid1 - staticTP * _Point);
//        }
//
//
//     }

OnTickMartins();


   if(Customtrailing == true)
     {

      Trailing();
     }

   if(Unitrailing == true)
     {
      UnitrailTick();
     }

  }
//+------------------------------------------------------------------+



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
//|                                                                  |
//+------------------------------------------------------------------+
bool TrailingMAInit(void)
  {
//---
   ResetLastError();
   if(!m_symbol.Name(Symbol())) // sets symbol name
     {
      Print(__FILE__," ",__FUNCTION__,", ERROR: CSymbolInfo.Name");
      return(false);
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
      return(false);
     }
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UnitrailInit()
  {
   if(VirtualTrailingStop)
      GeneralNoLoss=true;
   string txt;
   switch(parameters_trailing)
     {
      case 1: // по экстремумам свечей
         StringConcatenate(txt,"по свечам ",StrPer(TF_Tralling)," +- ",delta);
         break;
      case 2: // по фракталам
         StringConcatenate(txt,"по фракталам ",StrPer(TF_Tralling)," +- ",delta);
         break;
      case 3: // по индикатору ATR
         StringConcatenate(txt,"по ATR (",IntegerToString(period_ATR),") ",StrPer(TF_Tralling),"+- ",delta);
         atrHandle=iATR(_Symbol,TF_Tralling,period_ATR);
         break;
      case 4: // по индикатору Parabolic
         StringConcatenate(txt,"по параболику (",DoubleToString(Step,2)," ",DoubleToString(Maximum,2),") ",StrPer(TF_Tralling)," +- ",delta);
         sarHandle=iSAR(_Symbol,TF_Tralling,Step,Maximum);
         break;
      case 5: // по индикатору МА
         StringConcatenate(txt,"по MA (",ma_period," ",ma_method," ",applied_price,") ",StrPer(TF_Tralling)," +- ",delta);
         maHandle=iMA(_Symbol,TF_Tralling,ma_period,0,ma_method,applied_price);
         break;
      case 6: // % от профита
         StringConcatenate(txt," ",DoubleToString(PercetnProfit,2),"% от профита)");
         break;
      default: // по пунктам
         StringConcatenate(txt,"по пунктам ",delta," п");
         break;
     }
   if(VirtualTrailingStop)
     {
      StringConcatenate(txt,"Виртуальный трал ",txt);
     }
   else
     {
      StringConcatenate(txt,"Tрал ",txt);
     }
   DrawLABEL(3,"cm 3",txt,5,30,text_color,ANCHOR_RIGHT);

   return(INIT_SUCCEEDED);
  }
//--------------------------------------------------------------------
void UnitrailTick()
  {
   long OT;
   int n=0;
   double OOP=0;
   string txt;
   StringConcatenate(txt,"Balance ",DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
   DrawLABEL(2,"cm Balance",txt,5,20,Lime,ANCHOR_RIGHT);
   StringConcatenate(txt,"Equity ",DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));
   DrawLABEL(2,"cm Equity",txt,5,35,Lime,ANCHOR_RIGHT);
//----
   if(!VirtualTrailingStop)
      STOPLEVEL=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double sl,SL;
   Bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   Ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   int i,b=0,s=0;
   double PB=0,PS=0,OL=0,NLb=0,NLs=0,LS=0,LB=0;
//----
   for(i=0; i<PositionsTotal(); i++)
     {
      if(_Symbol==PositionGetSymbol(i))
        {
         if(Magic==OrderGetInteger(ORDER_MAGIC) || Magic==-1)
           {
            OL  = PositionGetDouble(POSITION_VOLUME);
            OOP = PositionGetDouble(POSITION_PRICE_OPEN);
            OT  = PositionGetInteger(POSITION_TYPE);
            if(OT==POSITION_TYPE_BUY)
              {
               PB += OOP*OL;
               LB+=OL;
               b++;
              }
            if(OT==POSITION_TYPE_SELL)
              {
               PS += OOP*OL;
               LS+=OL;
               s++;
              }
           }
        }
     }
//----
   if(LB!=0)
     {
      NLb=PB/LB;
      ARROW("cm_NL_Buy",NLb,clrAqua);
     }
   if(LS!=0)
     {
      NLs=PS/LS;
      ARROW("cm_NL_Sell",NLs,clrRed);
     }
//----
   request.symbol=_Symbol;
   for(i=0; i<PositionsTotal(); i++)
     {
      if(_Symbol==PositionGetSymbol(i))
        {
         if(Magic==OrderGetInteger(ORDER_MAGIC) || Magic==-1)
           {
            OL  = PositionGetDouble(POSITION_VOLUME);
            OOP = PositionGetDouble(POSITION_PRICE_OPEN);
            OT  = PositionGetInteger(POSITION_TYPE);
            sl=PositionGetDouble(POSITION_SL);
            if(OT==POSITION_TYPE_BUY)
              {
               if(VirtualTrailingStop)
                 {
                  SL=SlLastBar(POSITION_TYPE_BUY,Bid,NLb);
                  if(SL!=-1 && NLb+StartTrall*_Point<SL && SLB<SL)
                     SLB=SL;
                  if(SLB!=0)
                    {
                     HLINE("cm_slb",SLB,clrAqua);
                     if(Bid<=SLB)
                       {
                        request.deviation=slippage;
                        request.volume=PositionGetDouble(POSITION_VOLUME);
                        request.position=PositionGetInteger(POSITION_TICKET);
                        request.action=TRADE_ACTION_DEAL;
                        request.type_filling=ORDER_FILLING_FOK;
                        request.type=ORDER_TYPE_SELL;
                        request.price=Bid;
                        request.comment="";
                        if(!OrderSend(request,result))
                           Print("error ",GetLastError());
                       }
                    }
                 }
               else
                 {
                  SL=SlLastBar(POSITION_TYPE_BUY,Bid,OOP);
                  if(SL!=-1 && sl+StepTrall*_Point<SL && SL>=OOP+StartTrall*_Point)
                    {
                     request.action    = TRADE_ACTION_SLTP;
                     request.position  = PositionGetInteger(POSITION_TICKET);
                     request.sl        = SL;
                     request.tp        = PositionGetDouble(POSITION_TP);
                     if(!OrderSend(request,result))
                        Print("error ",GetLastError());
                    }
                 }
              }
            if(OT==POSITION_TYPE_SELL)
              {
               if(VirtualTrailingStop)
                 {
                  SL=SlLastBar(POSITION_TYPE_SELL,Ask,NLs);
                  if(SL!=-1 && (SLS==0 || SLS>SL) && SL<=NLs-StartTrall*_Point)
                     SLS=SL;
                  if(SLS!=0)
                    {
                     HLINE("cm_sls",SLS,clrRed);
                     if(Ask>=SLS)
                       {
                        request.volume=PositionGetDouble(POSITION_VOLUME);
                        request.position=PositionGetInteger(POSITION_TICKET);
                        request.action=TRADE_ACTION_DEAL;
                        request.type_filling=ORDER_FILLING_FOK;
                        request.type=ORDER_TYPE_BUY;
                        request.price=Ask;
                        request.comment="";
                        if(!OrderSend(request,result))
                           Print("error ",GetLastError());
                       }
                    }
                 }
               else
                 {
                  SL=SlLastBar(POSITION_TYPE_SELL,Ask,OOP);
                  if(SL!=-1 && (sl==0 || sl-StepTrall*_Point>SL) && SL<=OOP-StartTrall*_Point)
                    {
                     request.action    = TRADE_ACTION_SLTP;
                     request.position  = PositionGetInteger(POSITION_TICKET);
                     request.sl        = SL;
                     request.tp        = PositionGetDouble(POSITION_TP);
                     if(OrderCheck(request,check))
                        if(!OrderSend(request,result))
                           Print("error ",GetLastError());
                        else
                           Print("error ",GetLastError());
                    }
                 }
              }
           }
        }
     }

   if(b==0)
     {
      SLB=0;
      ObjectDelete(0,"cm SLb");
      ObjectDelete(0,"cm_SLb");
      ObjectDelete(0,"cm_slb");
     }
   if(s==0)
     {
      SLS=0;
      ObjectDelete(0,"cm SLs");
      ObjectDelete(0,"cm_SLs");
      ObjectDelete(0,"cm_sls");
     }
   return;
  }
//--------------------------------------------------------------------
void UnitrailDeinit()
  {
   ObjectsDeleteAll(0,"cm");
   Comment("");
   if(parameters_trailing==3)
      IndicatorRelease(atrHandle);
   if(parameters_trailing==4)
      IndicatorRelease(sarHandle);
   if(parameters_trailing==5)
      IndicatorRelease(maHandle);
  }
//--------------------------------------------------------------------
double SlLastBar(int tip,double price,double OOP)
  {
   double prc=0;
   int i;
   string txt;
   switch(parameters_trailing)
     {
      case 1: // по экстремумам свечей
         if(tip==POSITION_TYPE_BUY)
           {
            for(i=1; i<500; i++)
              {
               prc=NormalizeDouble(iLow(Symbol(),TF_Tralling,i)-delta*_Point,_Digits);
               if(prc!=0)
                  if(price-STOPLEVEL*_Point>prc)
                     break;
                  else
                     prc=0;
              }
            StringConcatenate(txt,"SL Buy candle ",DoubleToString(prc,_Digits));
           }
         if(tip==POSITION_TYPE_SELL)
           {
            for(i=1; i<500; i++)
              {
               prc=NormalizeDouble(iHigh(Symbol(),TF_Tralling,i)+delta*_Point,_Digits);
               if(prc!=0)
                  if(price+STOPLEVEL*_Point<prc)
                     break;
                  else
                     prc=0;
              }
            StringConcatenate(txt,"SL Sell candle ",DoubleToString(prc,_Digits));
           }
         break;

      case 2: // по фракталам
         if(tip==POSITION_TYPE_BUY)
           {
            for(i=2; i<100; i++)
              {
               if(iLow2(Symbol(),TF_Tralling,i)<iLow2(Symbol(),TF_Tralling,i+1) &&
                  iLow2(Symbol(),TF_Tralling,i)<iLow2(Symbol(),TF_Tralling,i-1) &&
                  iLow2(Symbol(),TF_Tralling,i)<iLow2(Symbol(),TF_Tralling,i+2))
                 {
                  prc=iLow2(Symbol(),TF_Tralling,i);
                  if(prc!=0)
                    {
                     prc=NormalizeDouble(prc-delta*_Point,_Digits);
                     if(price-STOPLEVEL*_Point>prc)
                        break;
                    }
                  else
                     prc=0;
                 }
              }
            StringConcatenate(txt,"SL Buy Fractals ",DoubleToString(prc,_Digits));
           }
         if(tip==POSITION_TYPE_SELL)
           {
            for(i=2; i<100; i++)
              {
               if(iHigh2(Symbol(),TF_Tralling,i)>iHigh2(Symbol(),TF_Tralling,i+1) &&
                  iHigh2(Symbol(),TF_Tralling,i)>iHigh2(Symbol(),TF_Tralling,i-1) &&
                  iHigh2(Symbol(),TF_Tralling,i)>iHigh2(Symbol(),TF_Tralling,i+2))
                 {
                  prc=iHigh2(Symbol(),TF_Tralling,i);
                  if(prc!=0)
                    {
                     prc=NormalizeDouble(prc+delta*_Point,_Digits);
                     if(price+STOPLEVEL*_Point<prc)
                        break;
                    }
                  else
                     prc=0;
                 }
              }
            StringConcatenate(txt,"SL Sell Fractals ",DoubleToString(prc,_Digits));
           }
         break;
      case 3: // по индикатору ATR
         ArraySetAsSeries(atrVal,true);
         if(CopyBuffer(atrHandle,0,0,3,atrVal)<0)
           {
            StringConcatenate(txt,"Ошибка ATR :",GetLastError());
            prc=-1;
            break;
           }
         prc=atrVal[1];
         if(tip==POSITION_TYPE_BUY)
           {
            prc=NormalizeDouble(Bid-prc-delta*_Point,_Digits);
            StringConcatenate(txt,"SL Buy ATR ",DoubleToString(prc,_Digits));
           }
         if(tip==POSITION_TYPE_SELL)
           {
            prc=NormalizeDouble(Ask+prc+delta*_Point,_Digits);
            StringConcatenate(txt,"SL Buy ATR ",DoubleToString(prc,_Digits));
           }
         break;

      case 4: // по индикатору Parabolic
         ArraySetAsSeries(sarVal,true);
         if(CopyBuffer(sarHandle,0,0,3,sarVal)<0)
           {
            StringConcatenate(txt,"Ошибка Parabolic SAR :",GetLastError());
            prc=-1;
            break;
           }
         prc=sarVal[1];
         if(tip==POSITION_TYPE_BUY)
           {
            prc=NormalizeDouble(prc-delta*_Point,_Digits);
            if(price-STOPLEVEL*_Point<prc)
               prc=0;
            StringConcatenate(txt,"SL Buy Parabolic ",DoubleToString(prc,_Digits));
           }
         if(tip==POSITION_TYPE_SELL)
           {
            prc=NormalizeDouble(prc+delta*_Point,_Digits);
            if(price+STOPLEVEL*_Point>prc)
               prc=0;
            StringConcatenate(txt,"SL Buy Parabolic ",DoubleToString(prc,_Digits));
           }
         break;

      case 5: // по индикатору МА
         ArraySetAsSeries(maVal,true);
         if(CopyBuffer(maHandle,0,0,3,maVal)<0)
           {
            StringConcatenate(txt,"Ошибка Moving Average :",GetLastError());
            prc=-1;
            break;
           }
         prc=maVal[1];
         if(tip==POSITION_TYPE_BUY)
           {
            prc=NormalizeDouble(prc-delta*_Point,_Digits);
            if(price-STOPLEVEL*_Point<prc)
               prc=0;
            StringConcatenate(txt,"SL Buy MA ",DoubleToString(prc,_Digits));
           }
         if(tip==POSITION_TYPE_SELL)
           {
            prc=NormalizeDouble(prc+delta*_Point,_Digits);
            if(price+STOPLEVEL*_Point>prc)
               prc=0;
            StringConcatenate(txt,"SL Sell MA ",DoubleToString(prc,_Digits));
           }
         break;
      case 6: // % от профита
         if(tip==POSITION_TYPE_BUY)
           {
            prc=NormalizeDouble(OOP+(price-OOP)/100*PercetnProfit,_Digits);
            StringConcatenate(txt,"SL Buy % ",DoubleToString(prc,_Digits));
           }
         if(tip==POSITION_TYPE_SELL)
           {
            prc=NormalizeDouble(OOP-(OOP-price)/100*PercetnProfit,_Digits);
            StringConcatenate(txt,"SL Sell % ",DoubleToString(prc,_Digits));
           }
         break;
      default: // по пунктам
         if(tip==POSITION_TYPE_BUY)
           {
            prc=NormalizeDouble(price-delta*_Point,_Digits);
            StringConcatenate(txt,"SL Buy pips ",DoubleToString(prc,_Digits));
           }
         if(tip==POSITION_TYPE_SELL)
           {
            prc=NormalizeDouble(price+delta*_Point,_Digits);
            StringConcatenate(txt,"SL Sell pips ",DoubleToString(prc,_Digits));
           }
         break;
     }
   if(tip==POSITION_TYPE_BUY)
     {
      ARROW("cm_SLb",prc,clrGray);
      DrawLABEL(3,"cm SLb",txt,5,50,Color(prc>OOP,clrGreen,clrGray),ANCHOR_RIGHT);
     }
   if(tip==POSITION_TYPE_SELL)
     {
      ARROW("cm_SLs",prc,clrGray);
      DrawLABEL(3,"cm SLs",txt,5,70,Color(prc<OOP,clrRed,clrGray),ANCHOR_RIGHT);
     }
   return(prc);
  }
//--------------------------------------------------------------------
string StrPer(int per)
  {
   if(per==PERIOD_CURRENT)
      per=Period();
   if(per > 0 && per < 31)
      return("M"+IntegerToString(per));
   if(per == PERIOD_H1)
      return("H1");
   if(per == PERIOD_H2)
      return("H2");
   if(per == PERIOD_H3)
      return("M3");
   if(per == PERIOD_H4)
      return("M4");
   if(per == PERIOD_H6)
      return("M6");
   if(per == PERIOD_H8)
      return("M8");
   if(per == PERIOD_H12)
      return("M12");
   if(per == PERIOD_D1)
      return("D1");
   if(per == PERIOD_W1)
      return("W1");
   if(per == PERIOD_MN1)
      return("MN1");
   return("ошибка периода");
  }
//+------------------------------------------------------------------+
void HLINE(string Name,double Price,color c)
  {
   ObjectDelete(0,Name);
   ObjectCreate(0,Name,OBJ_HLINE,0,0,Price,0,0,0,0);
   ObjectSetInteger(0,Name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,Name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,Name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,Name,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(0,Name,OBJPROP_WIDTH,1);
  }
//+------------------------------------------------------------------+
void ARROW(string Name,double Price,color c)
  {
   if(!DrawArrow)
      return;
   ObjectDelete(0,Name);
   ObjectCreate(0,Name,OBJ_ARROW_RIGHT_PRICE,0,TimeCurrent(),Price,0,0,0,0);
   ObjectSetInteger(0,Name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,Name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,Name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,Name,OBJPROP_WIDTH,1);
  }
//--------------------------------------------------------------------
void DrawLABEL(int c,string name,string text,int X,int Y,color clr,int ANCHOR=ANCHOR_LEFT,int FONTSIZE=8)
  {
   if(ObjectFind(0,name)==-1)
     {
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,c);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,X);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,Y);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,FONTSIZE);
      ObjectSetString(0,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR);
     }
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
  }
//--------------------------------------------------------------------
color Color(bool P,color c1,color c2)
  {
   if(P)
      return(c1);
   return(c2);
  }
//--------------------------------------------------------------------
double iLow2(string symbol,ENUM_TIMEFRAMES tf,int index)
  {
   if(index < 0)
      return(-1);
   double Arr[];
   if(CopyLow(symbol,tf, index, 1, Arr)>0)
      return(Arr[0]);
   else
      return(-1);
  }
//--------------------------------------------------------------------
double iHigh2(string symbol,ENUM_TIMEFRAMES tf,int index)
  {
   if(index < 0)
      return(-1);
   double Arr[];
   if(CopyHigh(symbol,tf, index, 1, Arr)>0)
      return(Arr[0]);
   else
      return(-1);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|           Martin for small deposits(barabashkakvn's edition).mq5 |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInitMartins()
  {
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRatesMartins();

   string err_text="";
   if(!CheckVolumeValue(lotSize,err_text))
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

   ExtTakeProfit=staticTP*m_adjusted_point;
      ExtStopLoss    = staticSL     * m_adjusted_point;

   ExtStep=InpStep*m_adjusted_point;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTickMartins()
  {
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   if(!RefreshRatesMartins())
     {
      PrevBars=iTime(m_symbol.Name(),Period(),1);
      return;
     }

   static int counter_skipped=0;
//--- 
   int      count_buys  =0;                     double price_lowest_buy    =DBL_MAX;
   int      count_sells =0;                     double price_highest_sell  =DBL_MIN;
   datetime last_deal_in=D'1970.12.21 00:00';   double total_profit        =0.0;
   CalculateAllPositions(count_buys,price_lowest_buy,
                         count_sells,price_highest_sell,
                         last_deal_in,total_profit);
   if(last_deal_in!=D'1970.12.21 00:00')
     {
      double array_open[];
      int copied=CopyOpen(m_symbol.Name(),Period(),TimeCurrent(),last_deal_in,array_open);
      if(copied>1)
         counter_skipped=copied-1;
      int d=0;
     }
   else
      counter_skipped=0;
//---
   bool need_to_open_a_buy=false;
   bool need_to_open_a_sell=false;
   if(count_buys!=0 && count_sells!=0) // error!
     {
      CloseAllPositions();
      PrevBars=iTime(m_symbol.Name(),Period(),1);
      return;
     }
   else if(count_buys==0 && count_sells==0)
     {
      double arr_close[];
      ArraySetAsSeries(arr_close,true);
      int copied=CopyClose(m_symbol.Name(),Period(),1,15,arr_close);
      if(copied!=15)
         return;
      if(IchimokuSignal == "Buy") // open buy
         need_to_open_a_buy=true;
      else if(IchimokuSignal == "Sell") // open sell
      need_to_open_a_sell=true;
     }

   if(counter_skipped<=InpBarsSkipped && (count_buys!=0 || count_sells!=0))
     {
      //--- check profit and return
      if(total_profit>InpMinProfit)
        {
         CloseAllPositions();
         return;
        }
      return;
     }
   if(count_buys==0 || count_sells==0) // check the opening of the position "sell"
     {
      if(count_buys==0 && count_sells>0)
        {
         if(m_symbol.Bid()-price_highest_sell>ExtStep)
            need_to_open_a_sell=true;
        }
      else if(count_sells==0 && count_buys>0)
        {
         if(price_lowest_buy-m_symbol.Ask()>ExtStep)
            need_to_open_a_buy=true;
        }
     }
//--- buy
   if(need_to_open_a_buy)
     {
      double sl=(staticSL==0)?0.0:m_symbol.Bid()+ExtStopLoss;
      double tp=(staticTP==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
      double coef=MathPow(InpIncreaseFactor,(double)count_buys);
      double lot=LotCheck(lotSize*coef);
      if(lot!=0.0 && lot<InpMaxLot)
         OpenBuy(sl,tp,lot);
     }
//--- sell
   if(need_to_open_a_sell)
     {
      double sl=(staticSL==0)?0.0:m_symbol.Bid()+ExtStopLoss;
      double tp=(staticTP==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
      double coef=MathPow(InpIncreaseFactor,(double)count_sells);
      double lot=LotCheck(lotSize*coef);
      if(lot!=0.0 && lot<InpMaxLot)
         OpenSell(sl,tp,lot);
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
//---

  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRatesMartins(void)
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
void CalculateAllPositions(int &count_buys,double &price_lowest_buy,
                           int &count_sells,double &price_highest_sell,
                           datetime  &last_deal_in,double &total_profit)
  {
   count_buys  =0;                     price_lowest_buy  =DBL_MAX;
   count_sells =0;                     price_highest_sell=DBL_MIN;
   last_deal_in=D'1970.12.21 00:00';   total_profit      =0.0;
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.Time()>last_deal_in)
               last_deal_in=m_position.Time();
            total_profit+=m_position.Swap()+m_position.Commission()+m_position.Profit();
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               count_buys++;
               if(m_position.PriceOpen()<price_lowest_buy) // the lowest position of "BUY" is found
                  price_lowest_buy=m_position.PriceOpen();
               continue;
              }
            else if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               count_sells++;
               if(m_position.PriceOpen()>price_highest_sell) // the highest position of "SELL" is found
                  price_highest_sell=m_position.PriceOpen();
               continue;
              }
           }
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp,double lot)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=lot)
        {
         if(m_trade.Buy(lot,NULL,m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
           }
        }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp,double lot)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=lot)
        {
         if(m_trade.Sell(lot,NULL,m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
           }
        }
//---
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResult(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result: "+trade.ResultRetcodeDescription());
   Print("deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("current bid price: "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("current ask price: "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("broker comment: "+trade.ResultComment());
   DebugBreak();
  }
//+------------------------------------------------------------------+
