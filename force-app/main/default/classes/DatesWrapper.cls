global class DatesWrapper implements Comparable{
    //varibles
    @AuraEnabled
    public Date startDate;
    @AuraEnabled
    public Date endDate; 
    
    //Constructor
    public DatesWrapper(Date startDate ,Date endDate){
        this.startDate = startDate;
        this.endDate = endDate;
    }

    global Integer compareTo(Object compareTo){
        DatesWrapper compareToDateWrap = (DatesWrapper)compareTo;
        Integer returnValue = 0;
        if(this.startDate > compareToDateWrap.startDate){
            returnValue = 1;
        } else if(this.startDate < compareToDateWrap.startDate){
            returnValue = -1;
        } else if(this.startDate==null && compareToDateWrap.startDate!=null){
            returnValue = -1;
        } else if(this.startDate!=null && compareToDateWrap.startDate==null){
            returnValue = 1;
        } else if(this.startDate == compareToDateWrap.startDate){
            if(this.endDate < compareToDateWrap.endDate){
                returnValue = -1;
            } else if(this.endDate > compareToDateWrap.endDate){
                returnValue = 1;
            }
        }
        return returnValue;
    }
}
