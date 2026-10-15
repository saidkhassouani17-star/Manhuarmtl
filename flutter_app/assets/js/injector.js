(function() {
    if (window.madomiInjected) return;
    window.madomiInjected = true;

    const MIN_WIDTH = 260;
    const MIN_HEIGHT = 350;

    function attachOverlay(img) {
        if (img.dataset.madomiAttached) return;
        img.dataset.madomiAttached = "true";

        const wrapper = document.createElement('div');
        wrapper.style.position = 'relative';
        wrapper.style.display = 'inline-block';
        wrapper.style.width = '100%';

        img.parentNode.insertBefore(wrapper, img);
        wrapper.appendChild(img);

        const badge = document.createElement('button');
        badge.innerText = '🌐 ترجمة بالـ GPU (Kaggle)';
        badge.style.position = 'absolute';
        badge.style.top = '12px';
        badge.style.right = '12px';
        badge.style.zIndex = '99999';
        badge.style.background = 'rgba(14, 18, 26, 0.90)';
        badge.style.color = '#00E5FF';
        badge.style.border = '1px solid #00E5FF';
        badge.style.padding = '8px 14px';
        badge.style.borderRadius = '20px';
        badge.style.fontWeight = 'bold';
        badge.style.fontSize = '12px';
        badge.style.cursor = 'pointer';

        badge.onclick = function(e) {
            e.preventDefault();
            e.stopPropagation();
            badge.innerText = '⏳ جاري المسح والترجمة على Kaggle...';
            badge.style.color = '#FFD740';

            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('translateImage', img.src).then(function(result) {
                    if (result && result.status === 'success') {
                        badge.innerText = '✅ تمت الترجمة (' + result.bubblesCount + ' فقاعات)';
                        badge.style.color = '#69F0AE';
                        if (result.cleanedImageBase64 && result.cleanedImageBase64.length > 50) {
                            img.src = 'data:image/jpeg;base64,' + result.cleanedImageBase64;
                        }
                        drawBubblesOnWebImage(wrapper, result.bubbles);
                    } else {
                        badge.innerText = '❌ تأكد من رابط سيرفر Kaggle';
                        badge.style.color = '#FF5252';
                    }
                });
            }
        };

        wrapper.appendChild(badge);
    }

    function drawBubblesOnWebImage(wrapper, bubbles) {
        bubbles.forEach(function(b) {
            const box = document.createElement('div');
            box.style.position = 'absolute';
            box.style.left = (b.x * 100) + '%';
            box.style.top = (b.y * 100) + '%';
            box.style.width = (b.w * 100) + '%';
            box.style.height = (b.h * 100) + '%';
            box.style.display = 'flex';
            box.style.alignItems = 'center';
            box.style.justifyContent = 'center';
            box.style.zIndex = '99998';
            box.style.direction = 'rtl';
            box.style.textAlign = 'center';
            box.style.fontWeight = '900';
            box.style.color = '#000000';
            box.style.textShadow = '-2px -2px 0 #FFF, 2px -2px 0 #FFF, -2px 2px 0 #FFF, 2px 2px 0 #FFF, 0px 0px 6px #FFF';
            box.style.fontSize = '13px';
            box.style.lineHeight = '1.2';
            box.innerText = b.translatedText;
            wrapper.appendChild(box);
        });
    }

    function scanImages() {
        document.querySelectorAll('img').forEach(img => {
            if (img.naturalWidth >= MIN_WIDTH && img.naturalHeight >= MIN_HEIGHT) {
                attachOverlay(img);
            } else {
                img.addEventListener('load', () => {
                    if (img.naturalWidth >= MIN_WIDTH && img.naturalHeight >= MIN_HEIGHT) {
                        attachOverlay(img);
                    }
                });
            }
        });
    }

    scanImages();
    setInterval(scanImages, 2500);
})();
