//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                                          Jose Martinez Hernandez |
//|                                         https://greaterwaves.com |
//+------------------------------------------------------------------+
#property copyright "Jose Martinez Hernandez"
#property link      "https://greaterwaves.com"

#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| CcTrade Class - Send Orders To Open, Close and Modify Positions  |
//+------------------------------------------------------------------+
//Custom Trade class, inherits from library CTrade

class CcTrade : public CTrade
{
   private:         
      string                     m_symbol;

   public:
      void                       SetSymbol(string pSymbol)        { m_symbol = pSymbol;                  }      
      bool                       SelectPositionBySymbolAndMagic() { return (SelectPosition(m_symbol));   }
      ENUM_ACCOUNT_MARGIN_MODE   GetMarginMode()                  { return m_margin_mode;                }

      bool                       PositionClose(ENUM_POSITION_TYPE pPosType);  

      datetime                   GetExpirationTime(ushort pOrderExpirationMinutes);	
      ulong                      GetPendingTicket();     
};


bool CcTrade::PositionClose(ENUM_POSITION_TYPE pPosType)
{
   bool res = false;
   
   int total = PositionsTotal();
   
   for(int i = total - 1; i >= 0; i--)
   {
      ulong positionTicket = PositionGetTicket(i);
      
      if(m_symbol == PositionGetString(POSITION_SYMBOL) && 
         m_magic == PositionGetInteger(POSITION_MAGIC) && 
         pPosType == (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))
      {
         res = PositionClose(positionTicket,-1);
         break;
      }
   }
   
   return res;
}

//Get expiration time for pending orders on seconds
datetime CcTrade::GetExpirationTime(ushort pOrderExpirationMinutes)
{
   datetime orderExpirationSeconds = 0;
   if(pOrderExpirationMinutes > 0) orderExpirationSeconds = TimeCurrent() + pOrderExpirationMinutes * 60;
   
   return orderExpirationSeconds; 
}

ulong CcTrade::GetPendingTicket()
{
	int total=OrdersTotal(); 
	   
   for(int i=total-1; i>=0; i--)
   {
      ulong orderTicket = OrderGetTicket(i);                   
      ulong magic       = OrderGetInteger(ORDER_MAGIC);              
      string symbol     = OrderGetString(ORDER_SYMBOL);
      
      if(magic==m_magic && symbol == m_symbol) return orderTicket;
   }
   
   return 0; 
}

//+------------------------------------------------------------------+
//| NON-CLASS TRADE FUNCTIONS                                        |
//+------------------------------------------------------------------+

// Adjust stop level
double AdjustAboveStopLevel(string pSymbol,double pCurrentPrice,double pPriceToAdjust,int pPointsToAdd = 10)
{
	double adjustedPrice = pPriceToAdjust;
	
	double point      = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	long stopsLevel   = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL);
	
	if(stopsLevel > 0)
	{
	   double stopsLevelPrice = stopsLevel * point;          //stops level points in price
	   stopsLevelPrice = pCurrentPrice + stopsLevelPrice;    //stops price level - distance from bid/ask
   	
   	double addPoints = pPointsToAdd * point;              //Points that will be added/subtracted to stops level price to make sure our price covers the distance
   	
   	if(adjustedPrice <= stopsLevelPrice + addPoints) 
   	{
   		adjustedPrice = stopsLevelPrice + addPoints;
   		Print("Price adjusted above stop level to "+ string(adjustedPrice));		
   	}
	}
	 
	return adjustedPrice;
}

double AdjustBelowStopLevel(string pSymbol,double pCurrentPrice,double pPriceToAdjust,int pPointsToAdd = 10)
{
	double adjustedPrice = pPriceToAdjust;
	
	double point      = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	long stopsLevel   = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL);
	
	if(stopsLevel > 0)
	{
	   double stopsLevelPrice = stopsLevel * point;          //stops level points in price
	   stopsLevelPrice = pCurrentPrice - stopsLevelPrice;    //stops price level - distance from bid/ask
   	
   	double addPoints = pPointsToAdd * point;              //Points that will be added/subtracted to stops level price to make sure our price covers the distance
   	
   	if(adjustedPrice >= stopsLevelPrice - addPoints) 
   	{
   		adjustedPrice = stopsLevelPrice - addPoints;
   		Print("Price adjusted below stop level to "+ string(adjustedPrice));		
   	}
	}
	 
	return adjustedPrice;
}

// Delay program execution when market is closed
void DelayOnMarketClose(ENUM_TIMEFRAMES pTimeframe)
{
   //Current time
   MqlDateTime time;
   TimeCurrent(time);
   
   if(MQLInfoInteger(MQL_TESTER) && time.hour==0)
   {
      if(pTimeframe >= PERIOD_H4) Sleep(1800000); //300000 5min 1800000 30min  3600000 60min 
      else                        Sleep(300000);
   }                                                                                                                                                                                                                                                                                               
}
//+------------------------------------------------------------------+