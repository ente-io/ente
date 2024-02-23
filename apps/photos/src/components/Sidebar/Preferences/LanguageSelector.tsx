import DropdownInput, { DropdownOption } from 'components/DropdownInput';
import { useLocalState } from '@ente/shared/hooks/useLocalState';
import { t } from 'i18next';
import { useRouter } from 'next/router';
import {
    type SupportedLocale,
    supportedLocales,
    closestSupportedLocale,
} from '@/ui/i18n';
import { LS_KEYS } from '@ente/shared/storage/localStorage';
import { getUserLocaleString } from '@ente/shared/storage/localStorage/helpers';

/**
 * Human readable name for each supported locale
 *
 * TODO (MR): This names themselves should be localized.
 */
export const localeName = (locale: SupportedLocale) => {
    switch (locale) {
        case 'en-US':
            return 'English';
        case 'fr-FR':
            return 'Français';
        case 'zh-CH':
            return '中文';
        case 'nl-NL':
            return 'Nederlands';
        case 'es-ES':
            return 'Español';
    }
};

const getLanguageOptions = (): DropdownOption<SupportedLocale>[] => {
    return supportedLocales.map((locale) => ({
        label: localeName(locale),
        value: locale,
    }));
};

export const LanguageSelector = () => {
    const [userLocale, setUserLocale] = useLocalState(
        LS_KEYS.LOCALE,
        closestSupportedLocale(getUserLocaleString())
    );

    const router = useRouter();

    const updateCurrentLocale = (newLocale: SupportedLocale) => {
        setUserLocale(newLocale);
        router.reload();
    };

    return (
        <DropdownInput
            options={getLanguageOptions()}
            label={t('LANGUAGE')}
            labelProps={{ color: 'text.muted' }}
            selected={userLocale}
            setSelected={updateCurrentLocale}
        />
    );
};
