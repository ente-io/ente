/**
 * Types for [piexifjs](https://github.com/hMatoba/piexifjs).
 *
 * Non exhaustive, only the function we need.
 */
declare module "piexifjs" {
    interface ExifObj {
        Exif?: Record<number, unknown>;
    }

    interface Piexifjs {
        /**
         * Get exif data as object.
         *
         * @param jpegData a string that starts with "data:image/jpeg;base64,"
         * (a data URL), "\xff\xd8", or "Exif".
         */
        load: (jpegData: string) => ExifObj;
        /**
         *  Get exif as string to insert into JPEG.
         *
         * @param exifObj An object obtained using {@link load}.
         */
        dump: (exifObj: ExifObj) => string;
        /**
         * Insert exif into JPEG.
         *
         * If {@link jpegData} is a data URL, returns the modified JPEG as a
         * data URL. Else if {@link jpegData} is binary as string, returns JPEG
         * as binary as string.
         */
        insert: (exifStr: string, jpegData: string) => string;
        /**
         * Keys for the tags in {@link ExifObj}.
         */
        ExifIFD: {
            DateTimeOriginal: number;
        };
    }
    const piexifjs: Piexifjs;
    export default piexifjs;
}
