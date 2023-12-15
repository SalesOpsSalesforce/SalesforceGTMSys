import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSettings from '@salesforce/apex/TrailshredController.getSettings';

export default class TrailshredRecordForm extends NavigationMixin(LightningElement) {

    /**
     * System provided on record pages.
     */
    @api
    recordId;

    /**
     * System provided on record pages.
     */
    @api
    objectApiName;

    /**
     * Provided by Aura wrapper components that
     * override standard actions to indicate if
     * this component is initially in view or edit mode.
     *
     * Use case: think user is looking at a list view and
     *           chooses the `edit` action; our component should
     *           display in edit mode, not start in view mode.
     */
    @api
    mode = 'view';

    /**
     * User provided in app builder.
     *
     * How many columns the <lightning-record-form> should display.
     */
    @api
    layoutColumns = 2;

    /**
     * User provided in app builder.
     *
     * Which page layout type the <lightning-record-form> should display.
     */
    @api
    layoutType = 'Full';

    /**
     * Populated by Apex in the connectedCallback hook.
     *
     * Defines the conditions when audio clips should play.
     */
    trailshredFieldValueSettings = [];

    /**
     * Populated by the `onload` event of <lightning-record-form>
     * so know what the current record's field values are to compare
     * to the `onsave` event to know if should play audio files.
     *
     * Because when <lightning-record-form> saves a record the `onload` event
     * may be fired multiple times before the `onsave` event, then we
     * need to keep a small cache of recently loaded record copies
     * so can iterate through them to find the one that happened just
     * prior to the save event. Meaning, after saving, the `onload` event
     * may fire 2+ times before `onsave`. The last `onload` just prior the
     * `onsave` will be the same record copy (most likely) which prevents us
     * from reliably comparing "old" and "new" values because they'd be the same.
     * The `onsave` handler has logic to traverse this cache and find the earlier loaded record
     * so can compare the "old" and "new" values to know if audio clips should play.
     */
    recordCache = [];

    connectedCallback() {
        const that = this;
        getSettings({
            'objectApiName' : this.objectApiName
        }).then( ( response ) => {
            that.onSettingsLoaded( response );
        }).catch( ( error ) => {
            throw error;
        });
    }

    /**
     * Callback when <lightning-record-form> loads the record.
     * Uses Lightning Data Service to receive real-time updates.
     *
     * Keep track of recent 'onload' records and when 'onsuccess' fires, iterate through the cached copies
     * in reverse order (most recent to oldest) and find the first one whose `systemModstamp` is strictly less than
     * the `systemModstamp` in the 'onsuccess' event -- this ensures we are comparing the "old" and "new" values.
     * It's possible that the 'onload' event fires multiple times, and before, the 'onsuccess' event, that's why this is necessary.
     */
    onRecordLoad( event ) {
        const record = ( event.detail && event.detail.records && event.detail.records[this.recordId] );
        this.addRecordToCache( record );
        this.handleRecordFields( record );
    }

    handleRecordFields( newRecord ) {

        if ( !newRecord ) {
            return;
        }

        if ( this.trailshredFieldValueSettings && this.trailshredFieldValueSettings.length > 0 ) {

            const that = this;
            const audios = [];

            const oldRecord = this.recordCache.find( ( record ) => {
                // find the version of the record that was loaded prior to this version
                // sometimes it's not the first in the cache because the new record version
                // gets loaded before the `onsuccess` event fires
                return ( record.systemModstamp < newRecord.systemModstamp );
            });

            if ( oldRecord && newRecord ) {

                this.clearRecordCache();
                this.addRecordToCache( newRecord );

                this.trailshredFieldValueSettings.forEach( ( setting ) => {

                    // remove object name from field name path
                    // custom metadata entity definition lookups store the value as `Object.Field`
                    let fieldName = setting.Field_Name__c;
                    if ( fieldName.startsWith( that.objectApiName + '.' ) ) {
                        fieldName = fieldName.substring( that.objectApiName.length + 1 );
                    }

                    // if the field name is an id field, like AccountId or Widget__c
                    // then this method computes the relationship field name, like Account or Widget__r
                    let lookupFieldName = that.getLookupFieldName( fieldName );

                    // get the old field value
                    // if its a lookup field then grab its id, else use the field's value as-is
                    let oldField = oldRecord.fields[fieldName];
                    let oldFieldValue = ( oldField.value && oldField.value.id ) || oldField.value;

                    // get the new field value
                    // if its a lookup field then grab its id, else use the field's value as-is
                    let newField = newRecord.fields[fieldName];
                    let newFieldValue = ( newField.value && newField.value.id ) || newField.value;

                    // for lookup fields, the id field counterpart has no display value property
                    // so have to check two different field paths on the new record
                    // Example: { "CreatedBy": { "displayValue": "Astro", ... }, "CreatedById": { "displayValue": null, "value": "005xxx" } }
                    let newFieldDisplayValue = ( newRecord.fields[fieldName].displayValue || newRecord.fields[lookupFieldName].displayValue );

                    // determine if the record's field value has changed to the target value
                    // we compare the setting's target value to both the raw field value and its display value
                    // so can match on either lookup field value's name or its id, or localized numbers/dates or their ISO values, etc.
                    let fieldValueChanged = ( oldFieldValue !== newFieldValue );
                    let newFieldValueMatchesTargetValue = ( newFieldValue === setting.Field_Value__c );
                    let newFieldDisplayValueMatchesTargetValue = ( newFieldDisplayValue === setting.Field_Value__c );

                    if ( fieldValueChanged && ( newFieldValueMatchesTargetValue || newFieldDisplayValueMatchesTargetValue ) ) {
                        let cacheBuster = new Date().getTime();
                        audios.push( new Audio( '/resource/' + cacheBuster + '/' + setting.Audio_Static_Resource_Path__c ) );
                    }

                });

            }

            this.playAudioFilesInSequence( audios )();

        }

    }

    /**
     * Designed to be called after retrieving the trailshred settings from Apex.
     * Typically invoked from `connectedCallback`.
     *
     * Loops through the settings and organizes them into two filtered lists
     * for simpler access in the `onsuccess` and `onerror` functions.
     */
    onSettingsLoaded( settings ) {
        const that = this;
        if ( settings && settings.length > 0 ) {
            this.trailshredFieldValueSettings = settings.filter( ( setting ) => {
                return ( setting.Active__c && setting.Object_Name__c === that.objectApiName && setting.Audio_Static_Resource_Path__c && setting.Field_Name__c );
            });
        }
    }

    /**
     * Given a field api name to a lookup field,
     * returns the equivalent api name for the lookup relationship.
     *
     * If the field api name is not a lookup field, then
     * the same value is returned.
     *
     * Examples:
     *      'CreatedById' => 'CreatedBy'
     *      'Person__c' => 'Person__r'
     */
    getLookupFieldName( fieldName ) {
        let lookupFieldName = fieldName;
        if ( fieldName ) {
            let lowercaseFieldName = fieldName.toLowerCase();
            if ( lowercaseFieldName.endsWith( 'id' ) ) {
                // standard fields are same name but without 'Id' suffix
                lookupFieldName = fieldName.slice( 0, -2 );
            } else if ( lowercaseFieldName.endsWith( '__c' ) ) {
                // custom fields have __r suffix instead of __c suffix
                lookupFieldName = fieldName.slice( 0, -1 ) + 'r';
            }
        }
        return lookupFieldName;
    }

    /**
     * Plays the audio files in the array in sequence,
     * starting at the given index.
     *
     * This function is recursively invoked by each played
     * audio file until all files have been played.
     *
     * Returns a no-arg function suitable as an event listener
     * to the HTMLAudioElement's `ended` event.
     */
    playAudioFilesInSequence( audios, currentIndex = 0 ) {
        const that = this;
        return function() {
            if ( currentIndex < audios.length ) {
                let audio = audios[currentIndex];
                audio.addEventListener( 'ended', that.playAudioFilesInSequence( audios, ++currentIndex ) );
                audio.load();
                audio.play();
            }
        };
    }

    /**
     * A record conforms to this JSON structure:
     * {
     *   "apiName": "Account",
     *   "fields": {
     *     "AnnualRevenue": {
     *         "displayValue": "$350,000", // localized format
     *         "value": 350000
     *     },
     *     "BillingStreet": {
     *         "displayValue": null, // text fields don't have display value
     *         "value": "525 S. Lexington Ave"
     *     },
     *     "Owner": { // lookup fields have more elaborate "value" property
     *         "displayValue": "User User",
     *         "value": {
     *             "apiName": "User",
     *             "childRelationships": {},
     *             "fields": {
     *                 "Id": {
     *                     "displayValue": null,
     *                     "value": "0051D000001GxWbQAK"
     *                 },
     *                 "Name": {
     *                     "displayValue": null,
     *                     "value": "User User"
     *                 }
     *             },
     *             "id": "0051D000001GxWbQAK",
     *             "lastModifiedById": "0051D000001GxWbQAK",
     *             "lastModifiedDate": "2019-02-10T20:58:32.000Z",
     *             "recordTypeInfo": null,
     *             "systemModstamp": "2019-02-10T20:58:32.000Z"
     *         }
     *     },
     *     "OwnerId": {
     *         "displayValue": null, // inspect look field to get display value
     *         "value": "0051D000001GxWbQAK"
     *     }
     *   },
     *   "id": "0011D00000SkOqTQAV",
     *   "lastModifiedById": "0051D000001GxWbQAK",
     *   "lastModifiedDate": "2019-02-11T06:22:18.000Z",
     *   "recordTypeInfo": null,
     *   "systemModstamp": "2019-02-11T06:22:18.000Z"
     * }
     */
    addRecordToCache( record, maxCachedRecords = 5 ) {
        // add record to front of the array
        // so most recent records are first when array is iterated
        if ( record ) {
            this.recordCache.unshift( record );
        }
        // truncate array to max quantity
        this.recordCache.length = Math.min( this.recordCache.length, Math.max( maxCachedRecords, 0 ) );
    }

    clearRecordCache() {
        // https://davidwalsh.name/empty-array
        // https://stackoverflow.com/questions/1232040/how-do-i-empty-an-array-in-javascript/1232046#1232046
        this.recordCache.length = 0;
    }

}