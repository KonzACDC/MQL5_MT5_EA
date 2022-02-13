//=====================================================================
//	The experimental Expert Advisor for checking the custom optimization criteria.
//=====================================================================

//---------------------------------------------------------------------
#property copyright 	"Dima S."
#property link      	"dimascub@mail.com"
#property version   	"1.00"
#property description "The experimental Expert Advisor for checking the custom optimization criteria"
#property description "= по кривой баланса ="
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//	Connected libraries:
//---------------------------------------------------------------------
#include <Trade\Trade.mqh>
#include <CustomOptimisation.mqh>
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//	External parameters:
//---------------------------------------------------------------------
input double   Lots=0.1;
//---------------------------------------------------------------------
input int      MA1Period = 200;
input int      MA2Period = 50;
input int      MA3Period = 21;

//---------------------------------------------------------------------
int   max_ma_period=0;
//---------------------------------------------------------------------
TCustomCriterionArray   *criterion_Ptr;
//---------------------------------------------------------------------
//	Handle of the initialization event:
//---------------------------------------------------------------------
int  OnInit()
  {
//	Find the maximal period for three periods:
   max_ma_period=MA1Period;
   if(MA2Period>max_ma_period)
     {
      max_ma_period=MA2Period;
     }
   if(MA3Period>max_ma_period)
     {
      max_ma_period=MA3Period;
     }

   criterion_Ptr=new TCustomCriterionArray();
   if(CheckPointer(criterion_Ptr)==POINTER_INVALID)
     {
      return(-1);
     }
   criterion_Ptr.Add(new TBalanceSlopeCriterion(Symbol(),10000.0));

   return(0);
  }
//---------------------------------------------------------------------
//	Handle of deinitialization event:
//---------------------------------------------------------------------
void  OnDeinit(const int _reason)
  {
   if(CheckPointer(criterion_Ptr)==POINTER_DYNAMIC)
     {
      delete(criterion_Ptr);
     }
  }

//---------------------------------------------------------------------
//	Handle of the event of coming of new tick by the current symbol:
//---------------------------------------------------------------------
int      current_signal=0;
int      prev_signal=0;
bool   is_first_signal=true;
static datetime   chart_last_bar_datetime=0;
//---------------------------------------------------------------------
void  OnTick()
  {
//	Wait for the beginning of new bar:
   if(CheakNewBar(Symbol(),Period(),chart_last_bar_datetime)!=1)
     {
      return;
     }

//	Get signal to open/close position:
   current_signal=GetSignal();
   if(is_first_signal==true)
     {
      prev_signal=current_signal;
      is_first_signal=false;
     }

//	Select position by the current symbol:
   if(PositionSelect(Symbol())==true)
     {
      //	Check if we need to close the opposite position:
      if(CheakPositionClose(current_signal)==1)
        {
         return;
        }
     }

//	Check the presence of BUY signal:
   if(CheckBuySignal(current_signal,prev_signal)==1)
     {
      CTrade   trade;
      trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,Lots,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,0);
     }

//	Check the presence of SELL signal:
   if(CheckSellSignal(current_signal,prev_signal)==1)
     {
      CTrade   trade;
      trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,Lots,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,0);
     }

//	Save the current signal:
   prev_signal=current_signal;
  }
//---------------------------------------------------------------------
//	The handler of the event of completion of another test pass:
//---------------------------------------------------------------------
double  OnTester()
  {
   double   param=0.0;

   if(CheckPointer(criterion_Ptr)!=POINTER_INVALID)
     {
      param=criterion_Ptr.GetCriterion();
     }

   return(param);
  }
//---------------------------------------------------------------------
//	Check if we need to close the position:
//---------------------------------------------------------------------
//	returns:
//		0 - no open position;
//		1 - position is already opened in direction of the signal;
//---------------------------------------------------------------------
int  CheakPositionClose(int _signal)
  {
   long      position_type=PositionGetInteger(POSITION_TYPE);

   if(_signal==1)
     {
      //	If a BUY position is already opened, return:
      if(position_type==(long)POSITION_TYPE_BUY)
        {
         return(1);
        }
     }

   if(_signal==-1)
     {
      //	If a SELL position is already opened, return:
      if(position_type==(long)POSITION_TYPE_SELL)
        {
         return(1);
        }
     }

//	Closing position:
   CTrade   trade;
   trade.PositionClose(Symbol(),10);

   return(0);
  }
//---------------------------------------------------------------------
//	Check if there is the Buy signal:
//---------------------------------------------------------------------
//	returns:
//		0 - no signal;
//		1 - there is the BUY signal;
//---------------------------------------------------------------------
int  CheckBuySignal(int _curr_signal,int _prev_signal)
  {
//	Check, if the direction of signal is changed to BUY:
   if(( _curr_signal==1 && _prev_signal==0) || (_curr_signal==1 && _prev_signal==-1))
     {
      return(1);
     }

   return(0);
  }
//---------------------------------------------------------------------
//	Check if there is the SELL signal:
//---------------------------------------------------------------------
//	returns:
//		0 - no signal;
//		1 - there is the SELL signal;
//---------------------------------------------------------------------
int  CheckSellSignal(int _curr_signal,int _prev_signal)
  {
//	Check if signal direction has changed to SELL:
   if(( _curr_signal==-1 && _prev_signal==0) || (_curr_signal==-1 && _prev_signal==1))
     {
      return(1);
     }

   return(0);
  }
//---------------------------------------------------------------------
//	Get signal for opening/closing position:
//---------------------------------------------------------------------
int  GetSignal()
  {
   double   current_rates[];

   ResetLastError();
   if(CopyClose(Symbol(),Period(),0,max_ma_period,current_rates)!=max_ma_period)
     {
      Print("Error of copying of CopyRates, Code = ",GetLastError());
      return(0);
     }

//	Get the signal of trend direction:
   return(TrendDetector(0,current_rates));
  }
//---------------------------------------------------------------------
//	Determine the current trend direction:
//---------------------------------------------------------------------
//	Returns:
//		-1 - trend down;
//		+1 - trend up;
//		 0 - trend is not determined;
//---------------------------------------------------------------------
int  TrendDetector(int _shift,const double &_price[])
  {
   double   current_ma1,current_ma2,current_ma3;
   int         trend_direction=0;

   current_ma1 = GetSimpleMA( max_ma_period, MA1Period, _price );
   current_ma2 = GetSimpleMA( max_ma_period, MA2Period, _price );
   current_ma3 = GetSimpleMA( max_ma_period, MA3Period, _price );

   if(current_ma3>current_ma2 && current_ma2>current_ma1)
     {
      trend_direction=1;
     }
   else if(current_ma3<current_ma2 && current_ma2<current_ma1)
     {
      trend_direction=-1;
     }

   return(trend_direction);
  }
//---------------------------------------------------------------------
//	Calculation of moving average:
//---------------------------------------------------------------------
double  GetSimpleMA(const int size,const int period,const double &price[])
  {
   double   result=0.0;

   for(int i=size-1; i>=size-period; i--)
     {
      result+=price[i];
     }
   result/=(( double)period);

   return(result);
  }
//---------------------------------------------------------------------
//	Returns a sign of appearance of a new bar:
//---------------------------------------------------------------------
//	- if it returns 1, there is a new bar;
//---------------------------------------------------------------------
int  CheakNewBar(string _symbol,ENUM_TIMEFRAMES _period,datetime &_last_dt)
  {
//	Request time of opening of last bar:
   datetime   curr_time=(datetime)SeriesInfoInteger(_symbol,_period,SERIES_LASTBAR_DATE);
   if(curr_time>_last_dt)
     {
      _last_dt=curr_time;
      return(1);
     }

   return(0);
  }
//---------------------------------------------------------------------
