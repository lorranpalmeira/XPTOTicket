using System;
using System.Collections.Generic;
using System.Linq.Expressions;

namespace XRTTicket.Contexts
{
    public interface IUnitOfWork<T> where T : class
    {
        int Save(T model);
        int Update(T model, int id);
        void Delete(T model);
        IEnumerable<T> GetAll();
        T GetById(object id);
        int Next();
        IEnumerable<T> Where(Expression<Func<T, bool>> expression);
        IEnumerable<T> OrderBy(Expression<System.Func<T, bool>> expression);
        

    }
}
