package com.kurandakimesaj.app

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity, FlutterActivity'den türer; arka plan ses servisinin
// activity'ye bağlanabilmesi için gerekli. Manifest'teki activity ADI
// değişmedi — deep-link ve paylaşım intent-filter'ları o ada bağlı.
class MainActivity : AudioServiceActivity()
