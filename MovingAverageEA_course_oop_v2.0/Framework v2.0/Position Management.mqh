//+------------------------------------------------------------------+
//|                                          Position Management.mqh |
//|                                          Jose Martinez Hernandez |
//|                                         https://greaterwaves.com |
//+------------------------------------------------------------------+
#property copyright "Jose Martinez Hernandez"
#property link      "https://greaterwaves.com"

#include "Trade.mqh"
//AdjustStopLvl is used by SL,TP, TSL & BE functions


//+------------------------------------------------------------------+
//| CPM Class - Stop Loss, Take Profit, TSL & BE                     |
//+------------------------------------------------------------------+

class CPM
{
	public:
   	MqlTradeRequest   request;
   	MqlTradeResult    result;                           
                           
                        CPM(void);
      
      double            CalculateStopLoss(string pSymbol,string pEntrySignal,int pSLFixedPoints,int pSLFixedPointsMA,double pMA);
      double            CalculateTakeProfit(string pSymbol,string pEntrySignal,int pTPFixedPoints);
     
      void              TrailingStopLoss(string pSymbol,ulong pMagic,int pTSLFixedPoints);   //Hedging
      void              TrailingStopLoss(string pSymbol,int pTSLFixedPoints);                //Netting   
      void              BreakEven(string pSymbol,ulong pMagic,int pBEFixedPoints);           //Hedging
      void              BreakEven(string pSymbol,int pBEFixedPoints);                        //Netting
};

//+------------------------------------------------------------------+
//| CPM Class Methods                                                |
//+------------------------------------------------------------------+

CPM::CPM()
{
   ZeroMemory(request);
   ZeroMemory(result);
}

double CPM::CalculateStopLoss(string pSymbol, string pEntrySignal, int pSLFixedPoints, int pSLFixedPointsMA, double pMA)
{
   double stopLoss = 0.0;
   double askPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
   double bidPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
   double tickSize = SymbolInfoDouble(pSymbol,SYMBOL_TRADE_TICK_SIZE);
   double point    = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
   
   if(pEntrySignal == "LONG")
   {
      if(pSLFixedPoints > 0){
         stopLoss = bidPrice - (pSLFixedPoints * point);}
      else if(pSLFixedPointsMA > 0){
         stopLoss = pMA - (pSLFixedPointsMA * point);}
      
      if(stopLoss > 0) stopLoss = AdjustBelowStopLevel(pSymbol,bidPrice,stopLoss);      
   }
   else if(pEntrySignal == "SHORT")
   {
      if(pSLFixedPoints > 0){
         stopLoss = askPrice + (pSLFixedPoints * point);}
      else if(pSLFixedPointsMA > 0){
         stopLoss = pMA + (pSLFixedPointsMA * point);} 
         
      if(stopLoss > 0) stopLoss = AdjustAboveStopLevel(pSymbol,askPrice,stopLoss);      
   }
   
   stopLoss = round(stopLoss/tickSize) * tickSize;
   return stopLoss;   
}

double CPM::CalculateTakeProfit(string pSymbol, string pEntrySignal, int pTPFixedPoints)
{
   double takeProfit = 0.0;
   double askPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
   double bidPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
   double tickSize = SymbolInfoDouble(pSymbol,SYMBOL_TRADE_TICK_SIZE);
   double point    = SymbolInfoDouble(pSymbol,SYMBOL_POINT);

   if(pEntrySignal == "LONG")
   {
      if(pTPFixedPoints > 0){
         takeProfit = bidPrice + (pTPFixedPoints * point);}
      
      if(takeProfit > 0) takeProfit = AdjustAboveStopLevel(pSymbol,bidPrice,takeProfit);   
   }
   else if(pEntrySignal == "SHORT")
   {
      if(pTPFixedPoints > 0){
         takeProfit = askPrice - (pTPFixedPoints * point);} 
     
      if(takeProfit > 0) takeProfit = AdjustBelowStopLevel(pSymbol,askPrice,takeProfit); 
   }
   
   takeProfit = round(takeProfit/tickSize) * tickSize;
   return takeProfit;   
}

//HEDGING
void CPM::TrailingStopLoss(string pSymbol,ulong pMagic,int pTSLFixedPoints)
{	
	for(int i = PositionsTotal() - 1; i >= 0; i--)
	{
      //Reset of request and result values
      ZeroMemory(request);
      ZeroMemory(result);
         	   
	   ulong positionTicket = PositionGetTicket(i);
	   PositionSelectByTicket(positionTicket);
   
      string posSymbol        = PositionGetString(POSITION_SYMBOL);   
	   ulong posMagic          = PositionGetInteger(POSITION_MAGIC);
	   ulong posType           = PositionGetInteger(POSITION_TYPE);
      double currentStopLoss  = PositionGetDouble(POSITION_SL);
      double tickSize         = SymbolInfoDouble(posSymbol,SYMBOL_TRADE_TICK_SIZE);
      double point            = SymbolInfoDouble(posSymbol,SYMBOL_POINT);   
      	   
	   double newStopLoss;
	   
	   if(posSymbol == pSymbol && posMagic == pMagic && posType == POSITION_TYPE_BUY)
	   {        
         double bidPrice = SymbolInfoDouble(posSymbol,SYMBOL_BID);  
         newStopLoss = bidPrice - (pTSLFixedPoints * point);
         newStopLoss = AdjustBelowStopLevel(posSymbol,bidPrice,newStopLoss);         
         newStopLoss = round(newStopLoss/tickSize) * tickSize;
         
         if(newStopLoss > currentStopLoss)
         {
            request.action    = TRADE_ACTION_SLTP;
            request.position  = positionTicket;
            request.comment   = "TSL." + " | " + posSymbol + " | " + string(pMagic);
            request.sl        = newStopLoss;
            request.tp        = PositionGetDouble(POSITION_TP);          
         }     
	   }
	   else if(posSymbol == pSymbol && posMagic == pMagic && posType == POSITION_TYPE_SELL)
	   {                 
         double askPrice = SymbolInfoDouble(posSymbol,SYMBOL_ASK);                  
         newStopLoss = askPrice + (pTSLFixedPoints * point);
         newStopLoss = AdjustAboveStopLevel(posSymbol,askPrice,newStopLoss);
         newStopLoss = round(newStopLoss/tickSize) * tickSize;
         
         if(newStopLoss < currentStopLoss)
         {
            request.action    = TRADE_ACTION_SLTP;
            request.position  = positionTicket;
            request.comment   = "TSL." + " | " + posSymbol + " | " + string(pMagic);
            request.sl        = newStopLoss;  
            request.tp        = PositionGetDouble(POSITION_TP);                              
         }        
	   } 
      
      if(request.sl > 0)
      {
         bool sent = OrderSend(request,result);
   	   if(!sent) Print("OrderSend TSL error: ", GetLastError());           
      }
	}
}

//NETTING
void CPM::TrailingStopLoss(string pSymbol,int pTSLFixedPoints)
{	  	   
   if(!PositionSelect(pSymbol)) return;
   
   //Reset of request and result values
   ZeroMemory(request);
   ZeroMemory(result);

   string posSymbol        = PositionGetString(POSITION_SYMBOL);   
   ulong posType           = PositionGetInteger(POSITION_TYPE);
   double currentStopLoss  = PositionGetDouble(POSITION_SL);
   double tickSize         = SymbolInfoDouble(posSymbol,SYMBOL_TRADE_TICK_SIZE);	
   double point            = SymbolInfoDouble(posSymbol,SYMBOL_POINT);   
   double newStopLoss;
   
   if(posSymbol == pSymbol && posType == POSITION_TYPE_BUY)
   {     
      double bidPrice = SymbolInfoDouble(posSymbol,SYMBOL_BID);  
      newStopLoss = bidPrice - (pTSLFixedPoints * point);
      newStopLoss = AdjustBelowStopLevel(posSymbol,bidPrice,newStopLoss);         
      newStopLoss = round(newStopLoss/tickSize) * tickSize;
      
      if(newStopLoss > currentStopLoss)
      {
         request.action    = TRADE_ACTION_SLTP;
         request.symbol    = posSymbol;
         request.comment   = "TSL." + " | " + posSymbol;
         request.sl        = newStopLoss;
         request.tp        = PositionGetDouble(POSITION_TP);                
      }     
   }
   else if(posSymbol == pSymbol && posType == POSITION_TYPE_SELL)
   {                 
      double askPrice = SymbolInfoDouble(posSymbol,SYMBOL_ASK);                  
      newStopLoss = askPrice + (pTSLFixedPoints * point);
      newStopLoss = AdjustAboveStopLevel(posSymbol,askPrice,newStopLoss);
      newStopLoss = round(newStopLoss/tickSize) * tickSize;
      
      if(newStopLoss < currentStopLoss)
      {
         request.action    = TRADE_ACTION_SLTP;
         request.symbol    = posSymbol;
         request.comment   = "TSL." + " | " + posSymbol;
         request.sl        = newStopLoss; 
         request.tp        = PositionGetDouble(POSITION_TP);                          
      }        
   } 
   
   if(request.sl > 0)
   {
      bool sent = OrderSend(request,result);
	   if(!sent) Print("OrderSend TSL error: ", GetLastError());           
   }
}

//HEDGING
void CPM::BreakEven(string pSymbol,ulong pMagic,int pBEFixedPoints)
{	         	
	for(int i = PositionsTotal() - 1; i >= 0; i--)
	{
      //Reset of request and result values
      ZeroMemory(request);
      ZeroMemory(result);
         	   
	   ulong positionTicket = PositionGetTicket(i);
	   PositionSelectByTicket(positionTicket);
	   
      string posSymbol        = PositionGetString(POSITION_SYMBOL);   
	   ulong posMagic          = PositionGetInteger(POSITION_MAGIC);
	   ulong posType           = PositionGetInteger(POSITION_TYPE);   
      double currentStopLoss  = PositionGetDouble(POSITION_SL);   
      double tickSize         = SymbolInfoDouble(pSymbol,SYMBOL_TRADE_TICK_SIZE);	
	   double openPrice        = PositionGetDouble(POSITION_PRICE_OPEN);    
      double point            = SymbolInfoDouble(pSymbol,SYMBOL_POINT);   	     	   
	   double newStopLoss      = round(openPrice/tickSize) * tickSize;
	   
	   if(posSymbol == pSymbol && posMagic == pMagic && posType == POSITION_TYPE_BUY)
	   {        
         double bidPrice      = SymbolInfoDouble(pSymbol,SYMBOL_BID);         
         double BEThreshold   = openPrice + (pBEFixedPoints*point);
         
         if(newStopLoss > currentStopLoss && bidPrice > BEThreshold)
         {
            request.action    = TRADE_ACTION_SLTP;
            request.position  = positionTicket;
            request.comment   = "BE." + " | " + pSymbol + " | " + string(pMagic);
            request.sl        = newStopLoss;
            request.tp        = PositionGetDouble(POSITION_TP);                      
         }     
	   }
	   else if(posSymbol == pSymbol && posMagic == pMagic && posType == POSITION_TYPE_SELL)
	   {                 
         double askPrice      = SymbolInfoDouble(pSymbol,SYMBOL_ASK);                  
         double BEThreshold   = openPrice - (pBEFixedPoints*point);
         
         if(newStopLoss < currentStopLoss && askPrice < BEThreshold)
         {
            request.action    = TRADE_ACTION_SLTP;
            request.position  = positionTicket;
            request.comment   = "BE." + " | " + pSymbol + " | " + string(pMagic);
            request.sl        = newStopLoss;
            request.tp        = PositionGetDouble(POSITION_TP);                              
         }        
	   } 
      
      if(request.sl > 0)
      {
         bool sent = OrderSend(request,result);
   	   if(!sent) Print("OrderSend BE error: ", GetLastError());           
      }      
	}
}

//NETTING
void CPM::BreakEven(string pSymbol,int pBEFixedPoints)
{	         	
   if(!PositionSelect(pSymbol)) return;
   
   //Reset of request and result values
   ZeroMemory(request);
   ZeroMemory(result);

   string posSymbol        = PositionGetString(POSITION_SYMBOL);   
   ulong posMagic          = PositionGetInteger(POSITION_MAGIC);
   ulong posType           = PositionGetInteger(POSITION_TYPE);   
   double currentStopLoss  = PositionGetDouble(POSITION_SL);   
   double tickSize         = SymbolInfoDouble(pSymbol,SYMBOL_TRADE_TICK_SIZE);	
   double openPrice        = PositionGetDouble(POSITION_PRICE_OPEN);    
   double point            = SymbolInfoDouble(pSymbol,SYMBOL_POINT);   	     	   
   double newStopLoss      = round(openPrice/tickSize) * tickSize;
   
   if(posSymbol == pSymbol && posType == POSITION_TYPE_BUY)
   {        
      double bidPrice      = SymbolInfoDouble(pSymbol,SYMBOL_BID);         
      double BEThreshold   = openPrice + (pBEFixedPoints*point);
      
      if(newStopLoss > currentStopLoss && bidPrice > BEThreshold)
      {
         request.action    = TRADE_ACTION_SLTP;
         request.symbol    = pSymbol;
         request.comment   = "BE." + " | " + pSymbol;
         request.sl        = newStopLoss; 
         request.tp        = PositionGetDouble(POSITION_TP);                          
      }     
   }
   else if(posSymbol == pSymbol && posType == POSITION_TYPE_SELL)
   {                 
      double askPrice      = SymbolInfoDouble(pSymbol,SYMBOL_ASK);                  
      double BEThreshold   = openPrice - (pBEFixedPoints*point);
      
      if(newStopLoss < currentStopLoss && askPrice < BEThreshold)
      {
         request.action    = TRADE_ACTION_SLTP;
         request.symbol    = pSymbol;
         request.comment   = "BE." + " | " + pSymbol;
         request.sl        = newStopLoss;
         request.tp        = PositionGetDouble(POSITION_TP);                   
      }        
   } 
   
   if(request.sl > 0)
   {
      bool sent = OrderSend(request,result);
	   if(!sent) Print("OrderSend BE error: ", GetLastError());           
   }            
}

