namespace XRTTicket.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class XRT001 : DbMigration
    {
        public override void Up()
        {
            CreateTable(
                "dbo.AspNetRoles",
                c => new
                    {
                        Id = c.String(nullable: false, maxLength: 128),
                        Name = c.String(),
                    })
                .PrimaryKey(t => t.Id);
            
            CreateTable(
                "dbo.Ticket",
                c => new
                    {
                        TicketId = c.Int(nullable: false, identity: true),
                        OpenDateAndTime = c.DateTime(nullable: false),
                        ClosedDateTime = c.DateTime(),
                        VersionId = c.Int(nullable: false),
                        PriorityId = c.Int(nullable: false),
                        CompanyId = c.Int(nullable: false),
                        IdExternal = c.Int(),
                        UserId = c.String(),
                        AnalystDesignated = c.String(),
                        Rate = c.Int(),
                        SlaExpiration = c.DateTime(nullable: false),
                        Environment = c.String(),
                        Impact = c.String(),
                        TicketTypeId = c.Int(nullable: false),
                        DuplicatedOf = c.Int(),
                        StatusId = c.Int(nullable: false),
                        ProductId = c.Int(nullable: false),
                        SubProductId = c.Int(nullable: false),
                        TaskId = c.Int(nullable: false),
                        Title = c.String(nullable: false, maxLength: 50),
                    })
                .PrimaryKey(t => t.TicketId);  
            
        }
        
        public override void Down()
        {
            DropTable("dbo.Ticket");
            DropTable("dbo.AspNetRoles");
        }
    }
}
