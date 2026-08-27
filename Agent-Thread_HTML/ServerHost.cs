using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

namespace EliteSoftwareTech.AgentThreadServer
{
    class Program
    {
        private static int port = 29585;
        private static string rootDir;
        private static readonly object fileLock = new object();
        private static JavaScriptSerializer serializer = new JavaScriptSerializer();

        static void Main(string[] args)
        {
            rootDir = AppDomain.CurrentDomain.BaseDirectory;

            // Check if invoked as CLI command to append data
            if (args.Length > 0 && args[0].StartsWith("-"))
            {
                HandleCliCommand(args);
                return;
            }

            if (args.Length > 0 && Directory.Exists(args[0]))
            {
                rootDir = args[0];
            }

            Console.Title = "EliteSoftwareTech Co. - Agent-Thread Server Backend (Port 29585)";

            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("================================================================================");
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("  ELITESOFTWARETECH CO. - AGENT-THREAD HTML SERVER BACKEND");
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("================================================================================");
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine("  Port:            " + port);
            Console.WriteLine("  Root Directory:  " + rootDir);
            Console.WriteLine("  CLI Engine:      ENABLED (Thread-Safe Parameter & API Appender)");
            Console.WriteLine();

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("  [ Available Access Endpoints ]");
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("  |-- Localhost:     http://localhost:" + port + "/");
            Console.WriteLine("  |-- Loopback:      http://127.0.0.1:" + port + "/");

            try
            {
                foreach (NetworkInterface ni in NetworkInterface.GetAllNetworkInterfaces())
                {
                    if (ni.OperationalStatus == OperationalStatus.Up && ni.NetworkInterfaceType != NetworkInterfaceType.Loopback)
                    {
                        foreach (UnicastIPAddressInformation ip in ni.GetIPProperties().UnicastAddresses)
                        {
                            if (ip.Address.AddressFamily == AddressFamily.InterNetwork)
                            {
                                string name = ni.Name.Length > 20 ? ni.Name.Substring(0, 20) : ni.Name.PadRight(20);
                                Console.ForegroundColor = ConsoleColor.Green;
                                Console.WriteLine("  |-- " + name + ": http://" + ip.Address.ToString() + ":" + port + "/");
                            }
                        }
                    }
                }
            }
            catch { }

            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("================================================================================");

            HttpListener listener = new HttpListener();
            bool started = false;

            string[] prefixes = new string[] {
                "http://+:" + port + "/",
                "http://*:" + port + "/",
                "http://localhost:" + port + "/"
            };

            foreach (string prefix in prefixes)
            {
                try
                {
                    listener.Prefixes.Clear();
                    listener.Prefixes.Add(prefix);
                    listener.Start();
                    started = true;
                    break;
                }
                catch { }
            }

            if (!started)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("  FAILED to bind to port " + port + ". Port may be in use.");
                Console.ResetColor();
                return;
            }

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("  Server Listening Status: ACTIVE (Listening on all network interfaces)");
            Console.ForegroundColor = ConsoleColor.Gray;
            Console.WriteLine("  Press Ctrl+C to terminate server execution...");
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("================================================================================");
            Console.ResetColor();

            Dictionary<string, string> mimeTypes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                { ".html", "text/html; charset=utf-8" },
                { ".htm", "text/html; charset=utf-8" },
                { ".json", "application/json; charset=utf-8" },
                { ".css", "text/css; charset=utf-8" },
                { ".js", "application/javascript; charset=utf-8" },
                { ".png", "image/png" },
                { ".jpg", "image/jpeg" },
                { ".jpeg", "image/jpeg" },
                { ".ico", "image/x-icon" },
                { ".svg", "image/svg+xml" },
                { ".md", "text/markdown; charset=utf-8" },
                { ".txt", "text/plain; charset=utf-8" }
            };

            while (true)
            {
                try
                {
                    HttpListenerContext context = listener.GetContext();
                    ThreadPool.QueueUserWorkItem((state) =>
                    {
                        HttpListenerContext ctx = (HttpListenerContext)state;
                        HttpListenerRequest req = ctx.Request;
                        HttpListenerResponse res = ctx.Response;

                        res.Headers.Add("Access-Control-Allow-Origin", "*");
                        res.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate");
                        res.Headers.Add("Pragma", "no-cache");
                        res.Headers.Add("Expires", "0");

                        string urlPath = req.Url.AbsolutePath;

                        // Handle API POST requests
                        if (req.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
                        {
                            HandleApiPostRequest(req, res);
                            return;
                        }

                        if (string.IsNullOrEmpty(urlPath) || urlPath == "/")
                        {
                            urlPath = "/index.html";
                        }

                        string relative = urlPath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
                        string localPath = Path.Combine(rootDir, relative);

                        if (File.Exists(localPath))
                        {
                            string ext = Path.GetExtension(localPath);
                            string mime;
                            if (!mimeTypes.TryGetValue(ext, out mime))
                            {
                                mime = "application/octet-stream";
                            }
                            res.ContentType = mime;

                            try
                            {
                                lock (fileLock)
                                {
                                    byte[] bytes = File.ReadAllBytes(localPath);
                                    res.ContentLength64 = bytes.Length;
                                    res.OutputStream.Write(bytes, 0, bytes.Length);
                                }
                                res.StatusCode = (int)HttpStatusCode.OK;
                            }
                            catch
                            {
                                res.StatusCode = (int)HttpStatusCode.InternalServerError;
                            }
                        }
                        else
                        {
                            res.StatusCode = (int)HttpStatusCode.NotFound;
                            byte[] errBytes = Encoding.UTF8.GetBytes("404 - File Not Found: " + urlPath);
                            res.ContentType = "text/plain; charset=utf-8";
                            res.ContentLength64 = errBytes.Length;
                            res.OutputStream.Write(errBytes, 0, errBytes.Length);
                        }

                        try { res.OutputStream.Close(); } catch { }
                    }, context);
                }
                catch
                {
                    break;
                }
            }
        }

        private static void HandleCliCommand(string[] args)
        {
            Dictionary<string, string> p = ParseArgs(args);

            string cmd = args[0].ToLower();

            lock (fileLock)
            {
                if (cmd == "-addthread" || cmd == "--add-thread")
                {
                    AddThreadData(p);
                }
                else if (cmd == "-addhistory" || cmd == "--add-history")
                {
                    AddHistoryData(p);
                }
                else if (cmd == "-addartifact" || cmd == "--add-artifact")
                {
                    AddArtifactData(p);
                }
                else if (cmd == "-addversion" || cmd == "--add-version")
                {
                    AddVersionData(p);
                }
                else if (cmd == "-addplan" || cmd == "--add-plan")
                {
                    AddPlanData(p);
                }
                else
                {
                    Console.WriteLine("Unknown command: " + cmd);
                }
            }
        }

        private static Dictionary<string, string> ParseArgs(string[] args)
        {
            var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            for (int i = 1; i < args.Length; i += 2)
            {
                if (i + 1 < args.Length && args[i].StartsWith("-"))
                {
                    dict[args[i].TrimStart('-')] = args[i + 1];
                }
            }
            return dict;
        }

        private static void AddThreadData(Dictionary<string, string> p)
        {
            string filePath = Path.Combine(rootDir, "thread_data.json");
            Dictionary<string, object> data = LoadJsonDict(filePath);

            string agentId = GetVal(p, "AgentId", "agent_" + Guid.NewGuid().ToString().Substring(0, 8));
            string agentName = GetVal(p, "AgentName", agentId);
            string agentRole = GetVal(p, "AgentRole", "Agent");
            string agentColor = GetVal(p, "AgentColor", "#38bdf8");

            List<object> agents = data.ContainsKey("agents") ? (data["agents"] as List<object>) ?? new List<object>() : new List<object>();
            bool agentExists = false;
            foreach (var a in agents)
            {
                var ad = a as Dictionary<string, object>;
                if (ad != null && ad.ContainsKey("id") && ad["id"].ToString().Equals(agentId, StringComparison.OrdinalIgnoreCase))
                {
                    agentExists = true;
                    break;
                }
            }
            if (!agentExists)
            {
                var newAgent = new Dictionary<string, object>
                {
                    { "id", agentId },
                    { "name", agentName },
                    { "role", agentRole },
                    { "color", agentColor }
                };
                agents.Add(newAgent);
                data["agents"] = agents;
            }

            List<object> threads = data.ContainsKey("threads") ? (data["threads"] as List<object>) ?? new List<object>() : new List<object>();
            var newThread = new Dictionary<string, object>
            {
                { "id", "msg-" + (threads.Count + 1).ToString("D3") },
                { "timestamp", DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") },
                { "sender_id", agentId },
                { "recipient", GetVal(p, "Recipient", "all") },
                { "subject", GetVal(p, "Subject", "Status Update") },
                { "content", GetVal(p, "Content", "") },
                { "status", GetVal(p, "Status", "complete") }
            };

            threads.Add(newThread);
            data["threads"] = threads;
            data["last_updated"] = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");

            SaveJsonDict(filePath, data);
            Console.WriteLine("[SUCCESS] Added Thread Message: " + GetVal(p, "Subject", ""));
        }

        private static void AddHistoryData(Dictionary<string, string> p)
        {
            string filePath = Path.Combine(rootDir, "history_data.json");
            Dictionary<string, object> data = LoadJsonDict(filePath);

            List<object> history = data.ContainsKey("history") ? (data["history"] as List<object>) ?? new List<object>() : new List<object>();
            var newEntry = new Dictionary<string, object>
            {
                { "milestone", GetVal(p, "Milestone", "M1") },
                { "timestamp", DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") },
                { "sender", GetVal(p, "Sender", "Agent") },
                { "recipient", GetVal(p, "Recipient", "All") },
                { "action", GetVal(p, "Action", "Status Update") },
                { "details", GetVal(p, "Details", "") }
            };

            history.Add(newEntry);
            data["history"] = history;

            SaveJsonDict(filePath, data);
            Console.WriteLine("[SUCCESS] Added History Record: " + GetVal(p, "Action", ""));
        }

        private static void AddArtifactData(Dictionary<string, string> p)
        {
            string filePath = Path.Combine(rootDir, "artifacts_data.json");
            Dictionary<string, object> data = LoadJsonDict(filePath);

            List<object> artifacts = data.ContainsKey("artifacts") ? (data["artifacts"] as List<object>) ?? new List<object>() : new List<object>();
            var newArtifact = new Dictionary<string, object>
            {
                { "name", GetVal(p, "Name", "Artifact") },
                { "path", GetVal(p, "Path", "") },
                { "architecture", GetVal(p, "Architecture", "x64") },
                { "size", GetVal(p, "Size", "0 KB") },
                { "target_os", GetVal(p, "TargetOS", "Windows Vista+") },
                { "status", GetVal(p, "Status", "Release") },
                { "sha256", GetVal(p, "SHA256", "N/A") },
                { "description", GetVal(p, "Description", "") }
            };

            artifacts.Add(newArtifact);
            data["artifacts"] = artifacts;
            data["last_updated"] = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");

            SaveJsonDict(filePath, data);
            Console.WriteLine("[SUCCESS] Added Artifact Record: " + GetVal(p, "Name", ""));
        }

        private static void AddVersionData(Dictionary<string, string> p)
        {
            string filePath = Path.Combine(rootDir, "artifacts_data.json");
            Dictionary<string, object> data = LoadJsonDict(filePath);

            List<object> vHistory = data.ContainsKey("version_history") ? (data["version_history"] as List<object>) ?? new List<object>() : new List<object>();
            var newVer = new Dictionary<string, object>
            {
                { "version", GetVal(p, "Version", "1.0.0.0") },
                { "timestamp", DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") },
                { "changes", GetVal(p, "Changes", "") },
                { "build_notes", GetVal(p, "BuildNotes", "") }
            };

            vHistory.Add(newVer);
            data["version_history"] = vHistory;

            SaveJsonDict(filePath, data);
            Console.WriteLine("[SUCCESS] Added Version Record: " + GetVal(p, "Version", ""));
        }

        private static void AddPlanData(Dictionary<string, string> p)
        {
            string filePath = Path.Combine(rootDir, "plan_data.json");
            Dictionary<string, object> data = LoadJsonDict(filePath);

            if (p.ContainsKey("Status"))
            {
                data["status"] = p["Status"];
            }

            SaveJsonDict(filePath, data);
            Console.WriteLine("[SUCCESS] Updated Plan Data.");
        }

        private static void HandleApiPostRequest(HttpListenerRequest req, HttpListenerResponse res)
        {
            string body = "";
            using (var reader = new StreamReader(req.InputStream, req.ContentEncoding))
            {
                body = reader.ReadToEnd();
            }

            try
            {
                var dict = serializer.Deserialize<Dictionary<string, string>>(body);
                string path = req.Url.AbsolutePath.ToLower();

                lock (fileLock)
                {
                    if (path == "/api/thread") AddThreadData(dict);
                    else if (path == "/api/history") AddHistoryData(dict);
                    else if (path == "/api/artifact") AddArtifactData(dict);
                    else if (path == "/api/version") AddVersionData(dict);
                    else if (path == "/api/plan") AddPlanData(dict);
                }

                res.StatusCode = 200;
                byte[] resp = Encoding.UTF8.GetBytes("{\"success\":true}");
                res.ContentType = "application/json";
                res.ContentLength64 = resp.Length;
                res.OutputStream.Write(resp, 0, resp.Length);
            }
            catch (Exception ex)
            {
                res.StatusCode = 400;
                byte[] resp = Encoding.UTF8.GetBytes("{\"error\":\"" + ex.Message + "\"}");
                res.ContentType = "application/json";
                res.ContentLength64 = resp.Length;
                res.OutputStream.Write(resp, 0, resp.Length);
            }

            try { res.OutputStream.Close(); } catch { }
        }

        private static Dictionary<string, object> LoadJsonDict(string path)
        {
            if (File.Exists(path))
            {
                try
                {
                    string content = File.ReadAllText(path);
                    return serializer.Deserialize<Dictionary<string, object>>(content) ?? new Dictionary<string, object>();
                }
                catch { }
            }
            return new Dictionary<string, object>();
        }

        private static void SaveJsonDict(string path, Dictionary<string, object> data)
        {
            string json = serializer.Serialize(data);
            File.WriteAllText(path, json);
        }

        private static string GetVal(Dictionary<string, string> dict, string key, string defaultVal)
        {
            if (dict.ContainsKey(key)) return dict[key];
            return defaultVal;
        }
    }
}
