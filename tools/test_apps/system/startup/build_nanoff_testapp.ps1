# Define the path to 'test_startup_main'
$file = "$ENV:IDF_PATH\tools\test_apps\system\startup\main\test_startup_main.c"
$content = Get-Content $file
$content = $content -replace "app_main running", "Hello from nanoCLR test app!!"
$content | Set-Content $file

#series to build
$series = @("esp32", "esp32s2", "esp32s3")

#build all series

foreach ($targetSeries in $series) {

    # reset location
    Set-Location "$ENV:IDF_PATH\tools\test_apps\system\startup"

    #delete build folder
    Remove-Item -Recurse -Force "$ENV:IDF_PATH\tools\test_apps\system\startup\build" -ErrorAction SilentlyContinue

    #create build folder
    New-Item -ItemType Directory -Force -Path "$ENV:IDF_PATH\tools\test_apps\system\startup\build"

    # remove sdkconfig file
    Remove-Item -Force "$ENV:IDF_PATH\tools\test_apps\system\startup\sdkconfig" -ErrorAction SilentlyContinue

    #run CMake prep
    Set-Location "$ENV:IDF_PATH\tools\test_apps\system\startup\build"
    cmake -DSDKCONFIG_DEFAULTS="sdkconfig.ci.$targetSeries" -DIDF_TARGET="$targetSeries" -GNinja ..

    #run build
    cmake --build .

    # generate partition tables
    # esp32 series
    if($targetSeries -eq "esp32")
    {
        ."$ENV:IDF_PATH\components\partition_table\gen_esp32part.py" --flash-size 2MB "E:/GitHub/nf-interpreter/targets/ESP32/_IDF/esp32/partitions_nanoclr_2mb.csv" "$ENV:IDF_PATH/tools/test_apps/system/startup/build/partitions_2mb.bin"
    }
    
    # esp32s2 and esp32s3 series
    if($targetSeries -eq "esp32s2" -or $targetSeries -eq "esp32s3")
    {
        ."$ENV:IDF_PATH\components\partition_table\gen_esp32part.py" --flash-size 4MB "E:/GitHub/nf-interpreter/targets/ESP32/_IDF/$targetSeries/partitions_nanoclr_4mb.csv" "$ENV:IDF_PATH/tools/test_apps/system/startup/build\partitions_4mb.bin"
    }

    #copy artifacts
    Copy-Item -Path "$ENV:IDF_PATH\tools\test_apps\system\startup\build\bootloader\bootloader.bin" -Destination "E:\GitHub\nf-nanoFirmwareFlasher\lib\${targetSeries}bootloader\bootloader.bin" -Force
    Copy-Item -Path "$ENV:IDF_PATH\tools\test_apps\system\startup\build\test_startup.bin" -Destination "E:\GitHub\nf-nanoFirmwareFlasher\lib\${targetSeries}bootloader\test_startup.bin" -Force
    Copy-Item -Path "$ENV:IDF_PATH\tools\test_apps\system\startup\build\partitions_2mb.bin" -Destination "E:\GitHub\nf-nanoFirmwareFlasher\lib\${targetSeries}bootloader\partitions_2mb.bin" -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$ENV:IDF_PATH\tools\test_apps\system\startup\build\partitions_4mb.bin" -Destination "E:\GitHub\nf-nanoFirmwareFlasher\lib\${targetSeries}bootloader\partitions_4mb.bin" -Force -ErrorAction SilentlyContinue
}
