
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
input    ENUM_TIMEFRAMES         IchimokuTF           = PERIOD_CURRENT;  //Ichimoku Timeframe
input int Inp_maxpositions = 1;
//ENUM_TIMEFRAMES         STOTF = MACDTF ;
//ENUM_TIMEFRAMES         STOTF2 = MACDTF2 ; 

 int maxPositions = Inp_maxpositions;


//--- input parameters
input group             "Ichimoku"
input int                  Inp_Ichimoku_tenkan_sen    = 9;           // Ichimoku: period of Tenkan-sen
input int                  Inp_Ichimoku_kijun_sen     = 26;          // Ichimoku: period of Kijun-sen
input int                  Inp_Ichimoku_senkou_span_b = 52;          // Ichimoku: period of Senkou Span B


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

int OnInit()
  {
   m_trade.SetExpertMagicNumber(InpMagic);
   //--- create handle of the indicator iIchimoku
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
   TrailingMAInit();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
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
   
  
   
   
   
   
   
   
   
 //  if(maxPositions != PositionsTotal() && KArray[0] < 20 && DArray[0] < 20 && macdArray[0] > 0 && KArray2[0] < 20 && macdArray2[0] > 0)
 if(maxPositions != PositionsTotal() && IchimokuSignal == "Buy")
   {
      m_trade.Buy(lotSize, _Symbol, Ask1, Ask1 - staticSL * _Point, Ask1 + staticTP * _Point);


   }
   
   
//   if(maxPositions != PositionsTotal() && KArray[0] > 80 && DArray[0] > 80 && macdArray[0] < 0 && KArray2[0] > 80 && macdArray2[0] < 0)
 if(maxPositions != PositionsTotal() && IchimokuSignal == "Sell")

   {
      m_trade.Sell(lotSize, _Symbol, Bid1, Bid1 + staticSL * _Point, Bid1 - staticTP * _Point);
   }
   
   
   

      Trailing(); 

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
     {
IchimokuSignal = "Buy";
            Print("IchimokuSignal BUY");
            return(true);

     }
//--- SELL Signal
   if((tenkan[2]>=kijun[2] && tenkan[1]<kijun[1] && m_symbol.Bid()<spana[2] && m_symbol.Bid()<spanb[2] && rates[1].open>rates[1].close))
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
