using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection; // <--- ADDED
using Microsoft.EntityFrameworkCore;           // <--- ADDED
using DotNetCoreSqlDb.Data;                    // <--- ADDED (Ensure this matches your Data folder namespace)

namespace DotNetCoreSqlDb
{
    public class Program
    {
        public static void Main(string[] args)
        {
            // 1. Build the host, but don't run it yet
            var host = CreateHostBuilder(args).Build();

            // 2. Create a scope to get services
            using (var scope = host.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                try
                {
                    // 3. Get the Database Context
                    // IMPORTANT: Verify 'MyDatabaseContext' matches the class name in your Data folder!
                    var context = services.GetRequiredService<MyDatabaseContext>();

                    // 4. Run Migrations (Creates tables if they don't exist)
                    context.Database.Migrate();
                }
                catch (Exception ex)
                {
                    var logger = services.GetRequiredService<ILogger<Program>>();
                    logger.LogError(ex, "An error occurred creating the DB.");
                }
            }

            // 5. Now run the application
            host.Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureLogging(logging =>
                {
                    logging.AddAzureWebAppDiagnostics();
                })
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}