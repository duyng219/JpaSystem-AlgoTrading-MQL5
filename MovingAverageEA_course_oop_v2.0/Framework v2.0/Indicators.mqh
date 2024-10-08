//+------------------------------------------------------------------+
//|                                                   Indicators.mqh |
//|                                          Jose Martinez Hernandez |
//|                                         https://greaterwaves.com |
//+------------------------------------------------------------------+
#property copyright "Jose Martinez Hernandez"
#property link      "https://greaterwaves.com"

#define VALUES_TO_COPY 10    // Constant passed to copybuffer function to specify how much data we want to copy from an indicator


//+------------------------------------------------------------------+
//| Base Class                                                       |
//+------------------------------------------------------------------+

class CIndicator
{
	protected:
		int         handle;
		
	public:
		double      main[];
	
		            CIndicator(void);
		
		virtual int Init(void) { return(handle); }	
		void        RefreshMain(void);
};

CIndicator::CIndicator(void)
{
	ArraySetAsSeries(main,true);
}

void CIndicator::RefreshMain(void)
{
	ResetLastError();
	
	if(CopyBuffer(handle,0,0,VALUES_TO_COPY,main) < 0)
      Print("FILL_ERROR: ", GetLastError());
}

//+------------------------------------------------------------------+
//| Moving Average                                                   |
//+------------------------------------------------------------------+

class CiMA : public CIndicator
{
	public:
		int Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pMAPeriod,int pMAShift,ENUM_MA_METHOD pMAMethod,ENUM_APPLIED_PRICE pMAPrice);
};

int CiMA::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pMAPeriod,int pMAShift,ENUM_MA_METHOD pMAMethod,ENUM_APPLIED_PRICE pMAPrice)
{
   //In case of error when initializing the MA, GetLastError() will get the error code and store it in _lastError. 
   //ResetLastError will change _lastError variable to 0 
   ResetLastError();
   
   //A unique identifier for the indicator. Used for all actions related to the indicator, such as copying data and removing the indicator
   handle = iMA(pSymbol,pTimeframe,pMAPeriod,pMAShift,pMAMethod,pMAPrice);
   
   if(handle == INVALID_HANDLE) 
   {
      return -1;
      Print("There was an error creating the MA indicator handle: ", GetLastError());                    
   }
   
   Print("MA Indicator handle initialized successfully");
   
   return(handle);
}

//+--------+// Moving Average Signal Functions //+--------+//

string MA_EntrySignal(double pPrice1,double pPrice2,double pMA1,double pMA2)
{
   string str = "";
   string indicatorValues;
   
   if(pPrice1 > pMA1 && pPrice2 <= pMA2) {str = "LONG";}
   else if(pPrice1 < pMA1 && pPrice2 >= pMA2) {str = "SHORT";}
   else {str = "NO_TRADE";}
   
   if(str == "LONG" || str == "SHORT")
   {
      StringConcatenate(indicatorValues,"MA 1: ", DoubleToString(pMA1,_Digits)," | ", "MA 2: ", DoubleToString(pMA2,_Digits)," | ",
                        "Close 1: ", DoubleToString(pPrice1,_Digits)," | ", "Close 2: ", DoubleToString(pPrice2,_Digits));
                          
      Print(str, " SIGNAL DETECTED", " | ", "Indicator Values: ", indicatorValues);     
   }
  
   return str;
}

string MA_ExitSignal(double pPrice1,double pPrice2,double pMA1,double pMA2)
{
   string str = "";
   string indicatorValues;
   
   if(pPrice1 > pMA1 && pPrice2 <= pMA2) {str = "EXIT_SHORT";}
   else if(pPrice1 < pMA1 && pPrice2 >= pMA2) {str = "EXIT_LONG";}
   else {str = "NO_EXIT";}
     
   if(str == "EXIT_LONG" || str == "EXIT_SHORT")
   {
      StringConcatenate(indicatorValues,"MA 1: ", DoubleToString(pMA1,_Digits)," | ", "MA 2: ", DoubleToString(pMA2,_Digits)," | ",
                        "Close 1: ", DoubleToString(pPrice1,_Digits)," | ", "Close 2: ", DoubleToString(pPrice2,_Digits));
                          
      Print(str, " SIGNAL DETECTED", " | ", "Indicator Values: ", indicatorValues);     
   }
   
   return str;
}


//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+

class CiBands : public CIndicator
{
	public:
	   double upper[], lower[];
	   
	   CiBands(void);
	   
		int Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pBBPeriod,int pBBShift,double pBBDeviation,ENUM_APPLIED_PRICE pBBPrice);	
		void RefreshUpper(void);
		void RefreshLower(void);
};

void CiBands::CiBands(void)
{
	ArraySetAsSeries(upper,true);
	ArraySetAsSeries(lower,true);
}

int CiBands::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pBBPeriod,int pBBShift,double pBBDeviation,ENUM_APPLIED_PRICE pBBPrice)
{
   //In case of error when initializing the MA, GetLastError() will get the error code and store it in _lastError. 
   //ResetLastError will change _lastError variable to 0 
   ResetLastError();
   
   //A unique identifier for the indicator. Used for all actions related to the indicator, such as copying data and removing the indicator
   handle = iBands(pSymbol,pTimeframe,pBBPeriod,pBBShift,pBBDeviation,pBBPrice);
   
   if(handle == INVALID_HANDLE) 
   {
      return -1;
      Print("There was an error creating the Bands indicator handle: ", GetLastError());                    
   }
   
   Print("Bands Indicator handle initialized successfully");
   
   return(handle);
}

void CiBands::RefreshUpper(void)
{
	ResetLastError();
	
	if(CopyBuffer(handle,1,0,VALUES_TO_COPY,upper) < 0)
      Print("FILL_ERROR: ", GetLastError());
}

void CiBands::RefreshLower(void)
{
	ResetLastError();
	
	if(CopyBuffer(handle,2,0,VALUES_TO_COPY,lower) < 0)
      Print("FILL_ERROR: ", GetLastError());
}


