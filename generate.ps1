# Nettoyage des dossiers vides créés par l'erreur
if (Test-Path "Backend") { Remove-Item -Recurse -Force Backend }
New-Item -ItemType Directory -Force -Path Backend | Out-Null

$services = @(
    @{name="candidate";    port="8081"; db="candidate_db"; dbPort="5431"; deps="web,data-jpa,postgresql,validation,actuator"},
    @{name="job";          port="8082"; db="job_db"; dbPort="5432"; deps="web,data-jpa,postgresql,validation,actuator"},
    @{name="application";  port="8083"; db="application_db"; dbPort="5433"; deps="web,data-jpa,postgresql,validation,actuator"},
    @{name="notification"; port="8084"; db="notification_db"; dbPort="5434"; deps="web,data-jpa,postgresql,validation,actuator"},
    @{name="common";       port="8085"; db="common_db"; dbPort="5435"; deps="web,data-jpa,postgresql,validation,actuator"},
    @{name="analytics";    port="8086"; db="analytics_db"; dbPort="27017"; deps="web,data-mongodb,actuator"}
)

foreach ($s in $services) {
    $svcName = "$($s.name)-service"
    $url = "https://start.spring.io/starter.zip?type=maven-project&language=java&packaging=jar&javaVersion=17&groupId=tn.esprit.jobboard&artifactId=$svcName&name=$svcName&packageName=tn.esprit.jobboard.$($s.name)&dependencies=$($s.deps)"
    
    Write-Host "Telechargement de $svcName..."
    curl.exe -s -o "$svcName.zip" "$url"
    Expand-Archive -Path "$svcName.zip" -DestinationPath "Backend\$svcName" -Force
    Remove-Item "$svcName.zip"

    # Configuration automatique du fichier application.properties
    $propFile = "Backend\$svcName\src\main\resources\application.properties"
    
    if ($s.name -eq "analytics") {
        $content = "server.port=$($s.port)`nspring.application.name=$svcName`nspring.data.mongodb.uri=mongodb://localhost:$($s.dbPort)/$($s.db)`nmanagement.endpoints.web.exposure.include=health,info"
    } else {
        $content = "server.port=$($s.port)`nspring.application.name=$svcName`nspring.datasource.url=jdbc:postgresql://localhost:$($s.dbPort)/$($s.db)`nspring.datasource.username=postgres`nspring.datasource.password=postgres`nspring.jpa.hibernate.ddl-auto=update`nmanagement.endpoints.web.exposure.include=health,info"
    }
    
    $content | Out-File -FilePath $propFile -Encoding utf8
    Write-Host "OK : $svcName cree et configure sur le port $($s.port)"
}
Write-Host "Generation et configuration terminees !"