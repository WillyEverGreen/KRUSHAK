import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Localization from 'expo-localization';

// Import translation files
import en from './locales/en.json';
import hi from './locales/hi.json';
import mr from './locales/mr.json';
import te from './locales/te.json';
import kn from './locales/kn.json';
import bn from './locales/bn.json';
import ta from './locales/ta.json';
import pa from './locales/pa.json';

const resources = {
    en: { translation: en },
    hi: { translation: hi },
    mr: { translation: mr },
    te: { translation: te },
    kn: { translation: kn },
    bn: { translation: bn },
    ta: { translation: ta },
    pa: { translation: pa },
};

const LANGUAGE_DETECTOR = {
    type: 'languageDetector',
    async: true,
    detect: async (callback: (lang: string) => void) => {
        try {
            // 1. Check saved language
            const savedLanguage = await AsyncStorage.getItem('user-language');
            if (savedLanguage) {
                return callback(savedLanguage);
            }
            // 2. Fallback to device language
            const locale = Localization.getLocales()[0].languageCode; // e.g., 'en'
            return callback(locale || 'en');
        } catch (error) {
            console.log('Error reading language', error);
            callback('en');
        }
    },
    init: () => { },
    cacheUserLanguage: async (language: string) => {
        try {
            await AsyncStorage.setItem('user-language', language);
        } catch (error) { }
    },
};

i18n
    .use(initReactI18next)
    .use(LANGUAGE_DETECTOR as any)
    .init({
        resources,
        fallbackLng: 'en',
        interpolation: {
            escapeValue: false, // react already safes from xss
        },
        react: {
            useSuspense: false, // for safe android loading
        }
    });

export default i18n;
