using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using XRTTicket.Models;

namespace XRTTicket.ClassesHelper
{
    public class ComboHelper
    {

        public static IEnumerable GetPriority(int priorityId)
        {
            var priority = Repository._priority.Where(c => c.PriorityId == priorityId).ToList();
                                    
            return priority = priority.OrderBy(c => c.PriorityLevel).ToList();
        }

        public static IEnumerable GetProduct(int productId)
        {
            var product = Repository._product_list.Where(p => p.ProductId == productId).ToList();

            return product = product.OrderBy(p => p.Name ).ToList();
        }


        public static IEnumerable GetSubProduct(int productId,int subProductId)
        {
            var subproduct = Repository._subproduct_list.Where(p => p.SubProductId == subProductId && p.ProductId == productId).ToList();

            return subproduct = subproduct.OrderBy(p => p.Name ).ToList();
        }

        public static IEnumerable GetTask(int productId, int subProductId,int taskId)
        {
            var task = Repository._task.Where(p => p.TaskId == taskId && p.ProductId == productId && p.SubProductId ==subProductId  ).ToList();

            return task = task.OrderBy(p => p.Name).ToList();
        }

        public static IEnumerable GetVersion(int versionId)
        {
            var version = Repository._patchlist.Where(p => p.VersionId == versionId).ToList();

            return version = version.OrderBy(p => p.VersionName ).ToList();
        }
    }
}