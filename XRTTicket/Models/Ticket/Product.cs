using System.ComponentModel.DataAnnotations;

namespace XRTTicket.Models.Ticket
{
    public class Product
    {
        [Key]
        public int ProductId { get; set; }
        public string Name { get; set; }
        
        public int SubProductId { get; set; }
        //[ForeignKey("SubProduct")]
        //public virtual ICollection<SubProduct> SubProduct { get; set; }
    }


    public class SubProduct
    {
        [Key]
        public int SubProductId { get; set; }
        
        public int ProductId { get; set; }
        public string Name { get; set; }
        
        public int Task { get; set; }
        //[ForeignKey("Task")]
        //public virtual ICollection<Task> Tasks { get; set; }
        //[ForeignKey("Product")]
        //public virtual ICollection<Product> Product { get; set; }
    }

    public class Task
    {
        [Key]
        public int TaskId { get; set; }
        
        public int ProductId { get; internal set; }
        
        public int SubProductId { get; set; }
        public string Name { get; set; }

        //[ForeignKey("Product")]
        //public virtual ICollection<Product> Product { get; set; }
        //[ForeignKey("SubProduct")]
        //public virtual ICollection<SubProduct> SubProduct { get; set; }

    }

}