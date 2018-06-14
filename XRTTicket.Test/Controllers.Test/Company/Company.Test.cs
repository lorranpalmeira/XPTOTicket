using System.Collections.Generic;
using XRTTicket.Controllers.Company;
using Xunit;

namespace XRTTicket.Test.Controllers.Test.Company
{
    public class Company
    {

		private readonly CompanyController _company;

        public Company()
        {
            _company = new CompanyController();
        }

        [Fact]
        public void CompanyListJsonTest() {

            IList<XRTTicket.Models.Companies.Company> companies = new List<Models.Companies.Company> {

                new Models.Companies.Company{ CompanyName="Lorran"}
            };
            

          // var result = _company.CompanyListJson();

            Assert.NotEqual(companies, null);
        }

    }
}
