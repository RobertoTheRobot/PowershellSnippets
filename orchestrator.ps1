

function scor-getJob {
    param([string]$jobId)
    $r = invoke-webrequest -uri ([string]::Format("https://XXXXXXXXXX/Orchestrator2012/Orchestrator.svc/Jobs(guid'{0}')/Instances",$jobId)) -Method Get -UseDefaultCredentials
    $res = Invoke-WebRequest (([xml]$r.content).feed.entry.id + "/Parameters") -UseDefaultCredentials
    ([xml]$res.content).feed.entry | % { $_.content.properties}
}
