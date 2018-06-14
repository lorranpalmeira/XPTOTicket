using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.Entity.Infrastructure;
using System.Data.Entity.ModelConfiguration.Conventions;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using System.Web;
using XRTTicket.Contexts;
using XRTTicket.Models.Ticket;

namespace XRTTicket.Contexts
{
    public class BaseContext<T> : DbContext where T : class
    {

        public DbSet<T> DbSet
        {
            get;
            set;
        }

       

        public BaseContext() : base("DefaultConnection")
        {
            //Caso a base de dados não tenha sido criada, 
            //ao iniciar a aplicação iremos criar
            Database.SetInitializer<BaseContext<T>>(null);
            
        }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {

            
            //Neste momento não iremos fazer nada, 
            //iremos voltar mais para frente para criar nosso mapeamos dinamicos
            base.OnModelCreating(modelBuilder);
            modelBuilder.Conventions.Remove<PluralizingTableNameConvention>();

            // Class Mapping from IMapping

            var typesToMapping = (from x in Assembly.GetExecutingAssembly().GetTypes()
                                  where x.IsClass && typeof(IMapping).IsAssignableFrom(x)
                                  select x).ToList();

            // Varrendo todos os tipos que são mapeamento 
            // Com ajuda do Reflection criamos as instancias 
            // e adicionamos no Entity Framework
            foreach (var mapping in typesToMapping)
            {
                dynamic mappingClass = Activator.CreateInstance(mapping);
                modelBuilder.Configurations.Add(mappingClass);
            }


        }

        public virtual void ChangeObjectState(object model, EntityState state)
        {
            //Aqui trocamos o estado do objeto, 
            //facilita quando temos alterações e exclusões
            ((IObjectContextAdapter)this)
                          .ObjectContext
                          .ObjectStateManager
                          .ChangeObjectState(model, state);
        }


        // Implement IUnitOfWork
        

       

        public virtual int Save(T model)
        {
            this.DbSet.Add(model);
            this.ChangeObjectState(model, EntityState.Added);
            return this.SaveChanges();
        }

        public virtual int Update(T model, int id)
        {
            var entity = DbSet.Find(id);
            this.Entry(entity).CurrentValues.SetValues(model);
            return this.SaveChanges();
        }

        public virtual void Delete(T model)
        {
            var entry = this.Entry(model);
            if (entry.State == EntityState.Detached)
                this.DbSet.Attach(model);

            this.ChangeObjectState(model, EntityState.Deleted);
            this.SaveChanges();
        }

        public virtual IEnumerable<T> GetAll()
        {
            return this.DbSet.ToList();
        }

        public virtual T GetById(object id)
        {
            return this.DbSet.Find(id);
        }
       
        public virtual IEnumerable<T> Where(Expression<Func<T, bool>> expression)
        {
            return this.DbSet.Where(expression);
        }

        public IEnumerable<T> OrderBy(Expression<Func<T, bool>> expression)
        {
            return this.DbSet.OrderBy(expression);
        }

        
    }

}
