public with sharing class Util {
   
    public static String getDayOfWeek(Date paramDate){
        Datetime dt = (DateTime)paramDate.addDays(1);
        return  dt.format('EEEE');
    }

    public static Integer getBusinessDatesCount(Date startDate, Date endDate){
        Integer count = 0;
        Date curDate = startDate;
        while (curDate <= endDate) {
            String dayOfWeek = getdayOfWeek(curDate);
            if(getDayOfWeek(curDate) != 'Friday' && getDayOfWeek(curDate) != 'Saturday') count++;
            curDate = curDate.addDays(1);
        }
        return count;
    }

}
