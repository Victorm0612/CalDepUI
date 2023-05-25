import { Pipe, PipeTransform } from '@angular/core';
import * as _ from 'lodash';

@Pipe({
  name: 'filterTeams'
})
export class FilterTeamsPipe implements PipeTransform {
  transform(value: number[], ...args: unknown[]): { local: number; visitante: number }[] {
    const matches = value
      .map((team, j) => ({
        local: team < 0 ? team*-1 : j+1,
        visitante: team < 0 ? j+1 : team
      }));
    return _.uniqBy(matches, 'local');
  }
}
