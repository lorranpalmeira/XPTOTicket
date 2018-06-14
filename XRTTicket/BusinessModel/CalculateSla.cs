using System;
using System.Linq;
using XRTTicket.Contexts;
using XRTTicket.DAO;
using XRTTicket.Models.Ticket;

namespace XRTTicket.BusinessModel
{
    public class CalculateSla
    {

        IUnitOfWork<ViewModelTicket> UnitOfTicket { get; set; }
        IUnitOfWork<Models.Ticket.Action> UnitOfTicketAction { get; set; }
        public CalculateSla()
        {
            this.UnitOfTicket = new TicketDao();
            this.UnitOfTicketAction = new ActionDao();
        }

        public static DateTime AddWithinWorkingHours(DateTime start, TimeSpan offset, int startHour, int hoursPerDay)
        {
            hoursPerDay = 8;
            startHour = 9;
            // Don't start counting hours until start time is during working hours
            if (start.TimeOfDay.TotalHours > startHour + hoursPerDay)
                start = start.Date.AddDays(1).AddHours(startHour);
            if (start.TimeOfDay.TotalHours < startHour)
                start = start.Date.AddHours(startHour);
            if (start.DayOfWeek == DayOfWeek.Saturday)
                start.AddDays(2);
            else if (start.DayOfWeek == DayOfWeek.Sunday)
                start.AddDays(1);
            // Calculate how much working time already passed on the first day
            TimeSpan firstDayOffset = start.TimeOfDay.Subtract(TimeSpan.FromHours(startHour));
            // Calculate number of whole days to add
            int wholeDays = (int)(offset.Add(firstDayOffset).TotalHours / hoursPerDay);
            // How many hours off the specified offset does this many whole days consume?
            TimeSpan wholeDaysHours = TimeSpan.FromHours(wholeDays * hoursPerDay);
            // Calculate the final time of day based on the number of whole days spanned and the specified offset
            TimeSpan remainder = offset - wholeDaysHours;
            // How far into the week is the starting date?
            int weekOffset = ((int)(start.DayOfWeek + 7) - (int)DayOfWeek.Monday) % 7;
            // How many weekends are spanned?
            int weekends = (int)((wholeDays + weekOffset) / 5);
            // Calculate the final result using all the above calculated values
            return start.AddDays(wholeDays + weekends * 2).Add(remainder);
            
        }

        public static double SubtractWithinWorkingHours(DateTime start, int TotalHours, int startHour=0, int hoursPerDay=0)
        {
            var totalHours = TotalHours;

            var mod = totalHours % 24;
            var days = (int)totalHours / 24;
            var rest = (int)totalHours;

            for (int i = 1; i <= days; i++)
            {
                if (start.DayOfWeek == DayOfWeek.Saturday)
                {
                    rest -= 24;
                }
                else if (start.DayOfWeek == DayOfWeek.Sunday)
                {
                    rest -= 24;
                }
                else
                {
                    rest -= 16;
                }
                start = start.AddDays(1);

            }


            return rest;

        }


        public double SlaRestTime(int ticketId) {

            var dateTicket = UnitOfTicket.Where(x => x.TicketId == ticketId)
                   .Select(x => x.SlaExpiration).FirstOrDefault();
           var diffTime = dateTicket.Subtract(DateTime.Now.ToLocalTime()).TotalHours;

            return diffTime;

        }

        



    }
}